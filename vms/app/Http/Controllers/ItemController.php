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
        return view('items.form', ['item' => new Item(['data' => ItemService::defaults()]), 'fields' => ItemService::fields('vendor')]);
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
            ? $back->with('status', '草稿已保存,但部分图片未上传')->withErrors(['images' => $errors])
            : $back->with('status', '草稿已保存,请确认图片后提交');
    }

    public function show(Item $item)
    {
        $this->mine($item)->load('images', 'histories');

        return view('items.show', ['item' => $item, 'fields' => ItemService::fields('vendor')]);
    }

    public function edit(Item $item)
    {
        $this->mine($item);
        if (! $item->editableByVendor()) {
            return redirect("/vms/items/{$item->id}")->with('warning', '当前状态不可修改');
        }
        $item->load('images');

        return view('items.form', ['item' => $item, 'fields' => ItemService::fields('vendor')]);
    }

    public function update(Request $r, Item $item)
    {
        $this->mine($item);
        abort_unless($item->editableByVendor(), 403);
        $r->validate(ItemService::draftRules($this->vendor(), $item), [], ItemService::attributeNames());
        $item->update(['sku_no' => $r->sku_no, 'title' => $r->title_zh_cn, 'data' => ItemService::extract($r->all(), 'vendor') + array_diff_key($item->data ?? [], array_flip(array_column(ItemService::fields('vendor'), 'key')))]);

        if ($r->input('action') === 'submit') {
            return $this->submit($item);
        }

        return back()->with('status', '草稿已保存');
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

        return redirect("/vms/items/{$item->id}")->with('status', '商品已提交,等待 eBest 运营处理');
    }

    public function destroy(Item $item)
    {
        $this->mine($item);
        abort_unless($item->status === 'draft', 403);
        foreach ($item->images as $img) {
            ImageService::remove($img);
        }
        $item->delete();

        return redirect('/vms/items')->with('status', '草稿已删除');
    }

    public function uploadImage(Request $r, Item $item)
    {
        $this->mine($item);
        abort_unless($item->editableByVendor(), 403);
        $kind = (string) $r->input('kind');
        $files = $r->file('images', []);
        $errors = $this->saveImages($item, $kind, (array) $files);
        $back = redirect("/vms/items/{$item->id}/edit#images");

        return $errors ? $back->withErrors(['images' => $errors]) : $back->with('status', '图片已上传');
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
                $errors[] = $file->getClientOriginalName().':上传失败,请重试';
            }
        }

        return $errors;
    }

    public function deleteImage(Item $item, ItemImage $image)
    {
        $this->mine($item);
        abort_unless($item->editableByVendor() && $image->item_id === $item->id, 403);
        ImageService::remove($image);

        return redirect("/vms/items/{$item->id}/edit#images")->with('status', '图片已删除');
    }

    public function export(Request $r)
    {
        $ids = (array) $r->input('ids', []);
        $q = $this->vendor()->items()->with('images', 'vendor')->orderBy('id');
        $ids ? $q->whereIn('id', $ids) : $q->whereIn('status', ['submitted', 'returned', 'imported', 'listed']);
        $items = $q->get();
        abort_if($items->isEmpty(), 404, '没有可导出的商品');
        $items->each->update(['exported_at' => now()]);

        return ExportService::items($items, 'import-items-'.now()->format('Ymd-His').'.xlsx');
    }
}
