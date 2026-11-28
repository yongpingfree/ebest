<?php

namespace App\Http\Controllers\Staff;

use App\Http\Controllers\Controller;
use App\Models\Item;
use App\Services\ExportService;
use App\Services\ItemService;
use Illuminate\Http\Request;

class ItemController extends Controller
{
    public function index(Request $r)
    {
        $q = Item::with('vendor')->latest('id');
        if ($r->filled('status')) {
            $q->where('status', $r->status);
        } else {
            $q->where('status', '!=', 'draft');
        }
        if ($r->filled('vendor_id')) {
            $q->where('vendor_id', $r->vendor_id);
        }
        if ($r->filled('q')) {
            $q->where(fn ($x) => $x->where('title', 'like', "%{$r->q}%")->orWhere('sku_no', 'like', "%{$r->q}%"));
        }

        return view('staff.items.index', ['items' => $q->paginate(30)->withQueryString()]);
    }

    public function show(Item $item)
    {
        $item->load('vendor', 'images', 'histories');

        return view('staff.items.show', ['item' => $item, 'vendorFields' => ItemService::fields('vendor'), 'opsFields' => ItemService::fields('ops')]);
    }

    public function updateOps(Request $r, Item $item)
    {
        $item->update(['data' => array_merge($item->data ?? [], ItemService::extract($r->all(), 'ops')), 'oms_item_no' => $r->input('oms_item_no') ?: $item->oms_item_no]);

        return back()->with('status', '运营字段已保存');
    }

    /** 上架后的标题/图片修改已在 OMS 同步,清除标记 */
    public function clearChanged(Item $item)
    {
        $item->update(['post_listing_changed_at' => null]);
        $item->logStatus($item->status, $item->status, '运营已同步上架后的修改', auth('staff')->user()->email);

        return back()->with('status', '已清除标记');
    }

    public function returnItem(Request $r, Item $item)
    {
        $r->validate(['reason' => ['required', 'string', 'max:1000']], ['reason.required' => '退回时必须填写原因']);
        abort_unless(in_array($item->status, ['submitted', 'imported'], true), 403);
        $from = $item->status;
        $item->update(['status' => 'returned', 'return_reason' => $r->reason]);
        $item->logStatus($from, 'returned', $r->reason, auth('staff')->user()->email);

        return back()->with('status', '已退回供应商修改');
    }

    public function mark(Request $r, Item $item, string $to)
    {
        $allowed = ['imported' => ['submitted'], 'listed' => ['submitted', 'imported']];
        abort_unless(isset($allowed[$to]) && in_array($item->status, $allowed[$to], true), 403);
        $from = $item->status;
        $item->update(['status' => $to]);
        $item->logStatus($from, $to, $r->input('note'), auth('staff')->user()->email);

        return back()->with('status', '状态已更新为「'.Item::STATUS[$to].'」');
    }

    public function export(Request $r)
    {
        $ids = (array) $r->input('ids', []);
        $q = Item::with('images', 'vendor')->orderBy('id');
        $ids ? $q->whereIn('id', $ids) : $q->where('status', 'submitted');
        $items = $q->get();
        abort_if($items->isEmpty(), 404, '没有可导出的商品');
        $items->each->update(['exported_at' => now()]);

        return ExportService::items($items, 'import-items-'.now()->format('Ymd-His').'.xlsx');
    }
}
