<?php

namespace App\Services;

use App\Models\Item;
use App\Models\ItemImage;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ImageService
{
    /** 校验尺寸,返回错误信息或 null */
    public static function validate(UploadedFile $file, string $kind): ?string
    {
        $spec = config("vms.image_kinds.$kind");
        if (! $spec) {
            return '未知的图片类型';
        }
        if (! in_array(strtolower($file->getClientOriginalExtension()), ['jpg', 'jpeg', 'png', 'webp', 'gif'], true)) {
            return '图片格式只支持 jpg、png、webp、gif';
        }
        if ($file->getSize() > config('vms.image_max_kb') * 1024) {
            return '图片不能超过 '.(config('vms.image_max_kb') / 1024).' MB';
        }
        $info = @getimagesize($file->getRealPath());
        if (! $info) {
            return '文件不是有效的图片';
        }
        [$w, $h] = $info;
        if ($spec['width'] && $w !== $spec['width']) {
            return "{$spec['label']}宽度必须为 {$spec['width']} 像素(当前 {$w}×{$h})";
        }
        if ($spec['height'] && $h !== $spec['height']) {
            return "{$spec['label']}高度必须为 {$spec['height']} 像素(当前 {$w}×{$h})";
        }
        if (! empty($spec['max_height']) && $h > $spec['max_height']) {
            return "{$spec['label']}高度不能超过 {$spec['max_height']} 像素(当前 {$w}×{$h})";
        }

        return null;
    }

    /** 存放路径 images/<uuid>-<原文件名>,与 OMS 现有图片规则一致 */
    public static function store(Item $item, UploadedFile $file, string $kind): ItemImage
    {
        $spec = config("vms.image_kinds.$kind");
        [$w, $h] = getimagesize($file->getRealPath());
        $orig = $file->getClientOriginalName();
        $safe = preg_replace('/[^A-Za-z0-9._-]+/', '_', $orig);
        if (! preg_match('/[A-Za-z0-9]/', pathinfo($safe, PATHINFO_FILENAME))) {
            $safe = 'image.'.strtolower($file->getClientOriginalExtension());
        }
        $name = Str::uuid().'-'.$safe;
        $disk = config('vms.image_disk');
        $key = 'images/'.$name;
        if ($disk === 's3') {
            self::applyS3Credentials();
        }
        if (Storage::disk($disk)->exists($key)) {
            throw new \RuntimeException('图片路径已存在,请重试');
        }
        // 与 OMS 一致:ACL=public-read,并带上 ContentType,浏览器才能直接显示
        $ok = Storage::disk($disk)->putFileAs('images', $file, $name, [
            'visibility' => 'public',
            'ContentType' => $file->getMimeType() ?: 'application/octet-stream',
        ]);
        if ($ok === false) {
            throw new \RuntimeException("图片写入 {$disk} 失败:$key");
        }

        if ($spec['single']) {
            foreach ($item->images()->where('kind', $kind)->get() as $old) {
                self::remove($old);
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

    public static function remove(ItemImage $img): void
    {
        try {
            if (config('vms.image_disk') === 's3') {
                self::applyS3Credentials();
            }
            Storage::disk(config('vms.image_disk'))->delete($img->path);
        } catch (\Throwable $e) {
            report($e);
        }
        $img->delete();
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
