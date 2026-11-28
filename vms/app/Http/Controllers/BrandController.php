<?php

namespace App\Http\Controllers;

use App\Models\Brand;
use App\Models\Item;
use App\Services\ImageService;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class BrandController extends Controller
{
    private function vendor()
    {
        return auth('vendor')->user();
    }

    private function mine(Brand $brand): Brand
    {
        abort_unless($brand->vendor_id === $this->vendor()->id, 404);

        return $brand;
    }

    public function index()
    {
        return view('brands.index', ['vendor' => $this->vendor(), 'brands' => $this->vendor()->brands]);
    }

    public function store(Request $r)
    {
        $v = $this->vendor();
        $data = $r->validate([
            'name' => ['required', 'string', 'max:120', Rule::unique('brands', 'name')->where('vendor_id', $v->id)],
            'name_en' => ['nullable', 'string', 'max:120'],
            'image' => ['required', 'file', 'mimes:jpg,jpeg,png,webp,gif', 'max:'.config('vms.image_max_kb')],
        ], [], ['name' => __('品牌名称'), 'name_en' => __('品牌英文名'), 'image' => __('品牌图片')]);

        try {
            [$key] = ImageService::putFile($r->file('image'));
        } catch (\Throwable $e) {
            report($e);

            return back()->withErrors(['image' => __('图片上传失败,请重试')])->withInput();
        }
        $v->brands()->create([
            'name' => trim($data['name']), 'name_en' => $data['name_en'] ?? null,
            'image_path' => $key, 'image_url' => ImageService::publicUrl($key),
        ]);

        return back()->with('status', __('品牌已添加'));
    }

    public function update(Request $r, Brand $brand)
    {
        $this->mine($brand);
        $data = $r->validate([
            'name' => ['required', 'string', 'max:120', Rule::unique('brands', 'name')->where('vendor_id', $brand->vendor_id)->ignore($brand->id)],
            'name_en' => ['nullable', 'string', 'max:120'],
            'image' => ['nullable', 'file', 'mimes:jpg,jpeg,png,webp,gif', 'max:'.config('vms.image_max_kb')],
        ], [], ['name' => __('品牌名称'), 'name_en' => __('品牌英文名'), 'image' => __('品牌图片')]);

        $upd = ['name_en' => $data['name_en'] ?? null];
        // eBest 已建立品牌 id 后,名称不能再改(WMS 中已按该名称建档)
        if (! $brand->ebest_brand_id) {
            $upd['name'] = trim($data['name']);
        }
        $oldKey = null;
        if ($r->hasFile('image')) {
            try {
                [$key] = ImageService::putFile($r->file('image'));
            } catch (\Throwable $e) {
                report($e);

                return back()->withErrors(['image' => __('图片上传失败,请重试')]);
            }
            $oldKey = $brand->image_path;
            $upd += ['image_path' => $key, 'image_url' => ImageService::publicUrl($key)];
        }
        $brand->update($upd);
        if ($oldKey) {
            $cdnOk = false;
            try {
                $cdnOk = ImageService::deleteKey($oldKey); // 旧图物理删除
            } catch (\Throwable $e) {
                report($e);
            }
            if (! $cdnOk) {
                return back()->with('status', __('品牌已更新'))->with('warning', __('旧图片未能从存储或 CDN 清除,在缓存过期前旧图地址可能仍可访问,请联系管理员检查 CDN 权限'));
            }
        }

        return back()->with('status', __('品牌已更新'));
    }

    public function destroy(Brand $brand)
    {
        $this->mine($brand);
        if ($brand->ebest_brand_id) {
            return back()->withErrors(['brand' => __('该品牌已在 eBest 建档,不能删除')]);
        }
        $used = Item::where('vendor_id', $brand->vendor_id)->get()->contains(fn ($i) => (string) $i->val('brand_ref') === (string) $brand->id);
        if ($used) {
            return back()->withErrors(['brand' => __('该品牌已被商品使用,不能删除')]);
        }
        if ($brand->image_path) {
            try {
                ImageService::deleteKey($brand->image_path);
            } catch (\Throwable $e) {
                report($e);

                return back()->withErrors(['brand' => __('图片文件删除失败,品牌未删除,请稍后重试')]);
            }
        }
        $brand->delete();

        return back()->with('status', __('品牌已删除'));
    }
}
