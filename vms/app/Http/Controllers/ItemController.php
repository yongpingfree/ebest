<?php

namespace App\Http\Controllers;

use App\Models\Item;
use App\Models\ItemImage;
use App\Services\ExportService;
use App\Services\ImageService;
use App\Services\ItemService;
use Illuminate\Http\Request;

class ItemController extends Controller
{
    private function vendor()
    {
        return auth('vendor')->user();
    }

    private function mine(Item $item): Item
    {
        abort_unless($item->vendor_id === $this->vendor()->id, 404);

        return $item;
    }

    /** 品牌下拉(本供应商的品牌)与分类、子分类联动数据 */
    private function lookups(): array
    {
        [$catParents, $catChildren] = \App\Models\Category::tree();

        return ['brands' => $this->vendor()->brands, 'catParents' => $catParents, 'catChildren' => $catChildren];
    }

    public function index(Request $r)
    {
        $q = $this->vendor()->items()->latest('id');
        if ($r->filled('status')) {
            $q->where('status', $r->status);
        }
        if ($r->filled('q')) {
            $q->where(fn ($x) => $x->where('title', 'like', "%{$r->q}%")->orWhere('sku_no', 'like', "%{$r->q}%"));
        }

        return view('items.index', ['items' => $q->paginate(20)->withQueryString()]);
    }

    public function create()
    {
        return view('items.form', ['item' => new Item(['data' => ItemService::defaults()]), 'fields' => ItemService::fields('vendor')] + $this->lookups());
    }

    public function store(Request $r)
    {
        $v = $this->vendor();
        $r->validate(ItemService::draftRules($v, null), [], ItemService::attributeNames());
        $item = $v->items()->create([
            'status' => 'draft', 'sku_no' => $r->sku_no, 'title' => $r->title_zh_cn,
            'data' => ItemService::extract($r->all(), 'vendor'),
        ]);
        $item->logStatus(null, 'draft', '创建草稿', $v->email);

        $errors = [];
        foreach (array_keys(config('vms.image_kinds')) as $kind) {
            $errors = array_merge($errors, $this->saveImages($item, $kind, (array) $r->file("new_images.$kind", [])));
        }
        $back = redirect("/vms/items/{$item->id}/edit");

        return $errors
            ? $back->with('status', __('草稿已保存,但部分图片未上传'))->withErrors(['images' => $errors])
            : $back->with('status', __('草稿已保存,请确认图片后提交'));
    }

    public function show(Item $item)
    {
        $this->mine($item)->load('images', 'histories');

        return view('items.show', ['item' => $item, 'fields' => ItemService::fields('vendor')]);
    }

    public function edit(Item $item)
    {
        $this->mine($item);
        if ($item->limitedEditableByVendor()) {
            $item->load('images');
            $fields = array_values(array_filter(ItemService::fields('vendor'), fn ($f) => in_array($f['key'], Item::LIMITED_FIELDS, true)));

            return view('items.limited', ['item' => $item, 'fields' => $fields]);
        }
        if (! $item->editableByVendor()) {
            return redirect("/vms/items/{$item->id}")->with('warning', __('当前状态不可修改'));
        }
        $item->load('images');

        return view('items.form', ['item' => $item, 'fields' => ItemService::fields('vendor')] + $this->lookups());
    }

    public function update(Request $r, Item $item)
    {
        $this->mine($item);
        if ($item->limitedEditableByVendor()) {
            return $this->updateLimited($r, $item);
        }
        abort_unless($item->editableByVendor(), 403);
        $r->validate(ItemService::draftRules($this->vendor(), $item), [], ItemService::attributeNames());
        $item->update(['sku_no' => $r->sku_no, 'title' => $r->title_zh_cn, 'data' => ItemService::extract($r->all(), 'vendor') + array_diff_key($item->data ?? [], array_flip(array_column(ItemService::fields('vendor'), 'key')))]);

        if ($r->input('action') === 'submit') {
            return $this->submit($item);
        }

        return back()->with('status', __('草稿已保存'));
    }

    /** 已导入 OMS / 已上架的商品:只允许改标题(中文标题、英文标题、短标题),其余字段不变 */
    private function updateLimited(Request $r, Item $item)
    {
        $r->validate([
            'title_zh_cn' => ['required', 'string', 'max:255'],
            'title_en' => ['nullable', 'string', 'max:255'],
            'short_title' => ['nullable', 'string', 'max:255'],
        ], [], ItemService::attributeNames());
        $data = $item->data ?? [];
        $changed = false;
        foreach (Item::LIMITED_FIELDS as $k) {
            $new = trim((string) $r->input($k));
            $new = $new === '' ? null : $new;
            if (($data[$k] ?? null) !== $new) {
                $changed = true;
            }
            $data[$k] = $new;
        }
        $item->update(['title' => $data['title_zh_cn'], 'data' => $data]);
        if ($changed) {
            $this->markPostListingChange($item, '上架后修改标题');
        }

        return back()->with('status', $changed ? __('标题已更新,eBest 运营会同步到商品系统') : __('没有变化'));
    }

    /** 记录上架后的修改,运营在 OMS 同步后清除标记 */
    private function markPostListingChange(Item $item, string $note): void
    {
        if ($item->limitedEditableByVendor()) {
            $item->update(['post_listing_changed_at' => now()]);
            $item->logStatus($item->status, $item->status, $note, $this->vendor()->email);
        }
    }

    public function submit(Item $item)
    {
        $this->mine($item);
        abort_unless($item->editableByVendor(), 403);
        $item->load('images', 'vendor');
        $errors = ItemService::missingForSubmit($item);
        if ($errors) {
            return redirect("/vms/items/{$item->id}/edit")->withErrors(['submit' => $errors]);
        }
        $from = $item->status;
        $item->update(['status' => 'submitted', 'submitted_at' => now(), 'return_reason' => null]);
        $item->logStatus($from, 'submitted', null, $this->vendor()->email);

        return redirect("/vms/items/{$item->id}")->with('status', __('商品已提交,等待 eBest 运营处理'));
    }

    public function destroy(Item $item)
    {
        $this->mine($item);
        abort_unless($item->status === 'draft', 403);
        try {
            foreach ($item->images as $img) {
                ImageService::remove($img, true);
            }
        } catch (\Throwable $e) {
            report($e);

            return back()->withErrors(['images' => __('图片文件删除失败,草稿未删除,请稍后重试')]);
        }
        $item->delete();

        return redirect('/vms/items')->with('status', __('草稿已删除'));
    }

    public function uploadImage(Request $r, Item $item)
    {
        $this->mine($item);
        abort_unless($item->imagesEditableByVendor(), 403);
        $kind = (string) $r->input('kind');
        $files = $r->file('images', []);
        ImageService::$cdnPurgeFailed = false;
        $errors = $this->saveImages($item, $kind, (array) $files);
        $back = redirect("/vms/items/{$item->id}/edit#images");
        if (! $errors) {
            $this->markPostListingChange($item, '上架后修改图片(上传)');
        }
        if ($errors) {
            return $back->withErrors(['images' => $errors]);
        }
        $back->with('status', __('图片已上传'));

        // 替换单图时旧图已从存储删除,但 CDN 缓存未清除(多为 IAM 无 CreateInvalidation 权限)
        return ImageService::$cdnPurgeFailed ? $back->with('warning', __('新图片已上传,旧图片文件已删除,但 CDN 缓存暂未清除,旧图地址在缓存过期前可能仍可访问,请联系管理员检查 CDN 权限')) : $back;
    }

    /** 校验并保存一组图片,返回错误信息列表 */
    private function saveImages(Item $item, string $kind, array $files): array
    {
        $errors = [];
        foreach ($files as $file) {
            if (! $file) {
                continue;
            }
            if ($msg = ImageService::validate($file, $kind)) {
                $errors[] = $file->getClientOriginalName().':'.$msg;

                continue;
            }
            try {
                ImageService::store($item, $file, $kind);
            } catch (\Throwable $e) {
                report($e);
                $errors[] = $file->getClientOriginalName().__(': 上传失败,请重试');
            }
        }

        return $errors;
    }

    public function deleteImage(Item $item, ItemImage $image)
    {
        $this->mine($item);
        abort_unless($item->imagesEditableByVendor() && $image->item_id === $item->id, 403);
        // 上架后必填图片不能删光:须先上传新图片(单图类型上传即替换)
        $spec = config("vms.image_kinds.{$image->kind}");
        if ($item->limitedEditableByVendor() && ! empty($spec['required']) && $item->images()->where('kind', $image->kind)->count() <= 1) {
            return redirect("/vms/items/{$item->id}/edit#images")->withErrors(['images' => __('必填图片不能删除,请先上传新图片替换')]);
        }
        try {
            $cdnOk = ImageService::remove($image, true);
        } catch (\Throwable $e) {
            report($e);

            return redirect("/vms/items/{$item->id}/edit#images")->withErrors(['images' => __('图片文件删除失败,请稍后重试')]);
        }

        $this->markPostListingChange($item, '上架后修改图片(删除)');
        $back = redirect("/vms/items/{$item->id}/edit#images")->with('status', __('图片已删除'));

        return $cdnOk ? $back : $back->with('warning', __('图片文件已删除,但 CDN 缓存暂未清除,在缓存过期前该图片地址可能仍可访问,请联系管理员检查 CDN 权限'));
    }

    public function export(Request $r)
    {
        $ids = (array) $r->input('ids', []);
        $q = $this->vendor()->items()->with('images', 'vendor')->orderBy('id');
        $ids ? $q->whereIn('id', $ids) : $q->whereIn('status', ['submitted', 'returned', 'imported', 'listed']);
        $items = $q->get();
        abort_if($items->isEmpty(), 404, __('没有可导出的商品'));
        $items->each->update(['exported_at' => now()]);

        return ExportService::items($items, 'import-items-'.now()->format('Ymd-His').'.xlsx');
    }
}
