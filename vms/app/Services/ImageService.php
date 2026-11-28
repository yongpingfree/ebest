<?php

namespace App\Services;

use App\Models\Item;
use App\Models\ItemImage;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ImageService
{
    /** 本次请求中,有旧图文件已删除但 CDN 缓存未能失效(替换旧图时设置,调用方据此提示) */
    public static bool $cdnPurgeFailed = false;

    /** 校验尺寸,返回错误信息或 null */
    public static function validate(UploadedFile $file, string $kind): ?string
    {
        $spec = config("vms.image_kinds.$kind");
        if (! $spec) {
            return __('未知的图片类型');
        }
        if (! in_array(strtolower($file->getClientOriginalExtension()), ['jpg', 'jpeg', 'png', 'webp', 'gif'], true)) {
            return __('图片格式只支持 jpg、png、webp、gif');
        }
        if ($file->getSize() > config('vms.image_max_kb') * 1024) {
            return __('图片不能超过 :n MB', ['n' => config('vms.image_max_kb') / 1024]);
        }
        $info = @getimagesize($file->getRealPath());
        if (! $info) {
            return __('文件不是有效的图片');
        }
        [$w, $h] = $info;
        if ($spec['width'] && $w !== $spec['width']) {
            return __(':label宽度必须为 :n 像素(当前 :w×:h)', ['label' => __($spec['label']), 'n' => $spec['width'], 'w' => $w, 'h' => $h]);
        }
        if ($spec['height'] && $h !== $spec['height']) {
            return __(':label高度必须为 :n 像素(当前 :w×:h)', ['label' => __($spec['label']), 'n' => $spec['height'], 'w' => $w, 'h' => $h]);
        }
        if (! empty($spec['max_height']) && $h > $spec['max_height']) {
            return __(':label高度不能超过 :n 像素(当前 :w×:h)', ['label' => __($spec['label']), 'n' => $spec['max_height'], 'w' => $w, 'h' => $h]);
        }

        return null;
    }

    /** 把文件写入图片盘,路径 images/<uuid>-<原文件名>,与 OMS 现有图片规则一致;返回 [key, 原文件名] */
    public static function putFile(UploadedFile $file, string $prefix = 'images'): array
    {
        $orig = $file->getClientOriginalName();
        $safe = preg_replace('/[^A-Za-z0-9._-]+/', '_', $orig);
        if (! preg_match('/[A-Za-z0-9]/', pathinfo($safe, PATHINFO_FILENAME))) {
            $safe = 'image.'.strtolower($file->getClientOriginalExtension());
        }
        $name = Str::uuid().'-'.$safe;
        $disk = config('vms.image_disk');
        $key = $prefix.'/'.$name;
        if ($disk === 's3') {
            self::applyS3Credentials();
        }
        if (Storage::disk($disk)->exists($key)) {
            throw new \RuntimeException('图片路径已存在,请重试');
        }
        // 与 OMS 一致:ACL=public-read,并带上 ContentType,浏览器才能直接显示
        $ok = Storage::disk($disk)->putFileAs($prefix, $file, $name, [
            'visibility' => 'public',
            'ContentType' => $file->getMimeType() ?: 'application/octet-stream',
        ]);
        if ($ok === false) {
            throw new \RuntimeException("图片写入 {$disk} 失败:$key");
        }

        return [$key, $orig];
    }

    public static function store(Item $item, UploadedFile $file, string $kind): ItemImage
    {
        $spec = config("vms.image_kinds.$kind");
        [$w, $h] = getimagesize($file->getRealPath());
        [$key, $orig] = self::putFile($file);

        if ($spec['single']) {
            foreach ($item->images()->where('kind', $kind)->get() as $old) {
                // 替换旧图:旧图文件删除/CDN 失效失败只记录日志并标记,不影响新图
                if (! self::remove($old)) {
                    self::$cdnPurgeFailed = true;
                }
            }
        }

        return $item->images()->create([
            'kind' => $kind, 'path' => $key, 'url' => self::publicUrl($key),
            'original_name' => $orig, 'width' => $w, 'height' => $h,
            'sort' => (int) $item->images()->where('kind', $kind)->max('sort') + 1,
        ]);
    }

    public static function publicUrl(string $key): string
    {
        if (config('vms.image_disk') === 's3') {
            return 'https://'.config('vms.image_cdn_host').'/'.$key;
        }

        return Storage::disk(config('vms.image_disk'))->url($key);
    }

    /**
     * 从存储盘物理删除一个文件,并(如配置了 VMS_CDN_DISTRIBUTION_ID)让 CDN 缓存失效。
     * 存储删除失败时抛出异常,调用方据此保留记录并提示;CDN 失效失败只记日志。
     * 返回 false 表示文件已删除但 CDN 缓存未能失效(如 IAM 无 cloudfront:CreateInvalidation 权限)。
     */
    public static function deleteKey(string $key): bool
    {
        $disk = config('vms.image_disk');
        if ($disk === 's3') {
            self::applyS3Credentials();
        }
        if (! Storage::disk($disk)->delete($key) && Storage::disk($disk)->exists($key)) {
            throw new \RuntimeException("图片删除失败:$key");
        }
        if ($disk === 's3' && config('vms.cdn_distribution_id')) {
            try {
                (new \Aws\CloudFront\CloudFrontClient([
                    'version' => 'latest',
                    'region' => 'us-east-1', // CloudFront 控制面固定在 us-east-1
                    'credentials' => ['key' => config('filesystems.disks.s3.key'), 'secret' => config('filesystems.disks.s3.secret')],
                ]))->createInvalidation([
                    'DistributionId' => config('vms.cdn_distribution_id'),
                    'InvalidationBatch' => ['CallerReference' => 'vms-'.Str::uuid(), 'Paths' => ['Quantity' => 1, 'Items' => ['/'.ltrim($key, '/')]]],
                ]);
            } catch (\Throwable $e) {
                report($e);

                return false;
            }
        }

        return true;
    }

    /** 删除商品图片记录及其文件。$strict=true 时文件删不掉就抛异常且保留记录 */
    public static function remove(ItemImage $img, bool $strict = false): bool
    {
        $cdnOk = true;
        try {
            $cdnOk = self::deleteKey($img->path);
        } catch (\Throwable $e) {
            report($e);
            if ($strict) {
                throw $e;
            }
            $cdnOk = false;
        }
        $img->delete();

        return $cdnOk;
    }

    /** .env 中的 AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY 存的是 base64 编码值,上传前解码后用于 S3 盘 */
    private static function applyS3Credentials(): void
    {
        foreach (['key' => 'AWS_ACCESS_KEY_ID', 'secret' => 'AWS_SECRET_ACCESS_KEY'] as $field => $envName) {
            $encoded = trim((string) config("vms.s3_raw.$field"));
            if ($encoded === '') {
                throw new \RuntimeException("S3 未配置:请在 .env 中设置 $envName(base64 编码值)");
            }
            $plain = base64_decode($encoded, true);
            if ($plain === false || trim($plain) === '') {
                throw new \RuntimeException("$envName 不是有效的 base64 值,请检查 .env");
            }
            config(["filesystems.disks.s3.$field" => trim($plain)]);
        }
        Storage::forgetDisk('s3'); // 丢弃已缓存的 S3 实例,让新密钥生效

        if (! config('filesystems.disks.s3.bucket')) {
            throw new \RuntimeException('S3 未配置:请在 .env 中设置 AWS_BUCKET');
        }
    }
}
