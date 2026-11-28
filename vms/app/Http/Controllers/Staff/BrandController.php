<?php

namespace App\Http\Controllers\Staff;

use App\Http\Controllers\Controller;
use App\Models\Brand;
use App\Models\VendorHistory;
use Illuminate\Http\Request;

class BrandController extends Controller
{
    public function index(Request $r)
    {
        $q = Brand::with('vendor')->latest('id');
        if ($r->input('status') === 'missing') {
            $q->whereNull('ebest_brand_id');
        } elseif ($r->input('status') === 'done') {
            $q->whereNotNull('ebest_brand_id');
        }
        if ($r->filled('q')) {
            $q->where(fn ($x) => $x->where('name', 'like', "%{$r->q}%")->orWhere('name_en', 'like', "%{$r->q}%")
                ->orWhereHas('vendor', fn ($v) => $v->where('name', 'like', "%{$r->q}%")));
        }

        return view('staff.brands.index', ['brands' => $q->paginate(30)->withQueryString()]);
    }

    /** 回填在 WMS/OMS 中建好的品牌 id */
    public function setId(Request $r, Brand $brand)
    {
        $d = $r->validate(['ebest_brand_id' => ['required', 'string', 'max:40', 'regex:/^\d+$/']], ['ebest_brand_id.regex' => '品牌 id 须为数字']);
        $staff = auth('staff')->user();
        $brand->update(['ebest_brand_id' => $d['ebest_brand_id'], 'ebest_brand_id_by' => $staff->email, 'ebest_brand_id_at' => now()]);
        VendorHistory::create(['vendor_id' => $brand->vendor_id, 'event' => '回填品牌编号', 'note' => $brand->name.' → '.$d['ebest_brand_id'], 'actor' => $staff->email]);

        return back()->with('status', "已保存品牌「{$brand->name}」的编号");
    }
}
