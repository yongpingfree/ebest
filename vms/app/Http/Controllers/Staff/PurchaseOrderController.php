<?php

namespace App\Http\Controllers\Staff;

use App\Http\Controllers\Controller;
use App\Models\PurchaseOrder;
use App\Services\ExportService;
use Illuminate\Http\Request;

class PurchaseOrderController extends Controller
{
    public function index(Request $r)
    {
        $q = PurchaseOrder::with('vendor')->withCount('lines')->where('status', '!=', 'draft')->latest('id');
        foreach (['status', 'vendor_id'] as $f) {
            if ($r->filled($f)) {
                $q->where($f, $r->$f);
            }
        }
        if ($r->filled('from')) {
            $q->whereDate('eta_date', '>=', $r->from);
        }
        if ($r->filled('to')) {
            $q->whereDate('eta_date', '<=', $r->to);
        }

        return view('staff.pos.index', ['pos' => $q->paginate(30)->withQueryString()]);
    }

    public function show(PurchaseOrder $po)
    {
        $po->load('vendor', 'lines.item', 'histories');

        return view('staff.pos.show', ['po' => $po]);
    }

    /** 运营导入 WMS 后回填 WMS 采购单号(FR-5.5,过渡期手工) */
    public function setWmsNo(Request $r, PurchaseOrder $po)
    {
        $r->validate(['wms_po_no' => ['required', 'string', 'max:60']]);
        $po->update(['wms_po_no' => $r->wms_po_no]);
        $po->logStatus($po->status, $po->status, '回填 WMS 采购单号 '.$r->wms_po_no, auth('staff')->user()->email);

        return back()->with('status', 'WMS 采购单号已回填');
    }

    /** 仓库按实际到库数量审核:一致 -> 已审核;不一致 -> 异常(FR-5.14~5.16) */
    public function review(Request $r, PurchaseOrder $po)
    {
        abort_unless(in_array($po->status, ['submitted', 'exception'], true), 403);
        $r->validate(['qty' => ['required', 'array'], 'qty.*' => ['nullable', 'integer', 'min:0'], 'note' => ['nullable', 'string', 'max:1000']]);
        $po->load('lines');
        $diff = [];
        foreach ($po->lines as $l) {
            $got = $r->qty[$l->id] ?? null;
            if ($got === null || $got === '') {
                return back()->withErrors(['qty' => '请填写每行的实际到库数量']);
            }
            $l->update(['approved_qty' => (int) $got]);
            if ((int) $got !== (int) $l->qty) {
                $diff[] = ($l->sku_no ?: $l->product_name).":采购单 {$l->qty},实际到库 {$got}";
            }
        }
        $from = $po->status;
        if ($diff) {
            $po->update(['status' => 'exception', 'exception_note' => implode("\n", $diff).($r->note ? "\n".$r->note : '')]);
            $po->logStatus($from, 'exception', implode('; ', $diff), auth('staff')->user()->email);

            return back()->with('warning', '数量不一致,已标记为异常采购单');
        }
        $po->update(['status' => 'approved', 'exception_note' => null]);
        $po->logStatus($from, 'approved', $r->note, auth('staff')->user()->email);

        return back()->with('status', '审核通过。库存入账与同步仍在 WMS 中完成。');
    }

    public function export(Request $r)
    {
        $ids = (array) $r->input('ids', []);
        $q = PurchaseOrder::with('lines')->orderBy('id');
        $ids ? $q->whereIn('id', $ids) : $q->where('status', 'submitted')->whereNull('wms_po_no');
        $pos = $q->get();
        abort_if($pos->isEmpty(), 404, '没有可导出的采购单');
        $pos->each->update(['exported_at' => now()]);

        return ExportService::purchaseOrders($pos, 'purchase-orders-'.now()->format('Ymd-His').'.xlsx');
    }
}
