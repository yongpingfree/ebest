<?php

namespace App\Http\Controllers;

use App\Models\PurchaseOrder;
use App\Services\ExportService;
use App\Services\PurchaseOrderService as Svc;
use Illuminate\Http\Request;

class PurchaseOrderController extends Controller
{
    private function vendor()
    {
        return auth('vendor')->user();
    }

    private function mine(PurchaseOrder $po): PurchaseOrder
    {
        abort_unless($po->vendor_id === $this->vendor()->id, 404);

        return $po;
    }

    public function index(Request $r)
    {
        $q = $this->vendor()->purchaseOrders()->withCount('lines')->latest('id');
        if ($r->filled('status')) {
            $q->where('status', $r->status);
        }

        return view('pos.index', ['pos' => $q->paginate(20)->withQueryString()]);
    }

    public function create()
    {
        $v = $this->vendor();
        $po = new PurchaseOrder([
            'vendor_name' => $v->name, 'purchase_date' => today(), 'purchaser' => $v->contact_name,
            'marketing_mode' => '自营', 'eta_date' => today(), 'sync_stock' => true,
            'delivery_mode' => request('mode', 'ebest'), 'reference_no' => Svc::autoReference($v),
        ]);

        return view('pos.form', ['po' => $po, 'items' => Svc::selectableItems($v), 'lines' => collect()]);
    }

    private function rules(): array
    {
        return [
            'delivery_mode' => ['required', 'in:vendor,ebest,jit'],
            'purchase_date' => ['required', 'date'],
            'purchaser' => ['required', 'string', 'max:120'],
            'marketing_mode' => ['required', 'in:'.implode(',', config('vms.marketing_modes'))],
            'eta_date' => ['required', 'date', 'after_or_equal:purchase_date'],
            'sync_stock' => ['required', 'in:0,1'],
            'reference_no' => ['nullable', 'string', 'max:60'],
            'note' => ['nullable', 'string', 'max:1000'],
            'lines' => ['array'],
        ];
    }

    private const LABELS = ['delivery_mode' => '配送方式', 'purchase_date' => '采购日期', 'purchaser' => '采购人', 'marketing_mode' => '营销模式', 'eta_date' => '预计到货时间', 'sync_stock' => '是否同步库存'];

    public function store(Request $r)
    {
        $v = $this->vendor();
        $d = $r->validate($this->rules(), [], self::LABELS);
        $po = $v->purchaseOrders()->create([
            'draft_no' => Svc::nextDraftNo($v), 'vendor_name' => $v->name, 'status' => 'draft',
            'reference_no' => $d['reference_no'] ?: Svc::autoReference($v),
        ] + collect($d)->except(['lines', 'reference_no'])->all());
        Svc::saveLines($po, $r->input('lines', []));
        $po->logStatus(null, 'draft', '创建草稿', $v->email);

        return redirect("/vms/pos/{$po->id}/edit")->with('status', '采购单草稿已保存');
    }

    public function show(PurchaseOrder $po)
    {
        $this->mine($po)->load('lines.item', 'histories');

        return view('pos.show', ['po' => $po]);
    }

    public function edit(PurchaseOrder $po)
    {
        $this->mine($po);
        if (! $po->editableByVendor()) {
            return redirect("/vms/pos/{$po->id}")->with('warning', '已提交的采购单不可修改');
        }
        $po->load('lines');
        $lastPrices = [];
        foreach ($po->lines as $l) {
            $lastPrices[$l->item_id] = Svc::lastPrice($this->vendor(), $l->sku_no, $po->id);
        }

        return view('pos.form', ['po' => $po, 'items' => Svc::selectableItems($this->vendor()), 'lines' => $po->lines, 'lastPrices' => $lastPrices]);
    }

    public function update(Request $r, PurchaseOrder $po)
    {
        $this->mine($po);
        abort_unless($po->editableByVendor(), 403);
        $d = $r->validate($this->rules(), [], self::LABELS);
        $po->update(collect($d)->except(['lines', 'reference_no'])->all() + ['reference_no' => $d['reference_no'] ?: Svc::autoReference($this->vendor())]);
        Svc::saveLines($po, $r->input('lines', []));

        if ($r->input('action') === 'submit') {
            return $this->submit($po);
        }

        return back()->with('status', '草稿已保存');
    }

    public function submit(PurchaseOrder $po)
    {
        $this->mine($po);
        abort_unless($po->editableByVendor(), 403);
        $po->load('lines.item', 'vendor');
        $errors = Svc::missingForSubmit($po);
        if ($errors) {
            return redirect("/vms/pos/{$po->id}/edit")->withErrors(['submit' => $errors]);
        }
        // 供应商配送:供应商确认可售后自行建单,无需 eBest 审核(FR-5.1)
        $to = $po->delivery_mode === 'vendor' ? 'approved' : 'submitted';
        $po->update(['status' => $to, 'submitted_at' => now()]);
        $po->logStatus('draft', $to, $to === 'approved' ? '供应商配送,无需 eBest 审核' : null, $this->vendor()->email);

        return redirect("/vms/pos/{$po->id}")->with('status', $to === 'approved' ? '采购单已生效(供应商配送无需审核)' : '采购单已提交,等待仓库审核');
    }

    public function destroy(PurchaseOrder $po)
    {
        $this->mine($po);
        abort_unless($po->status === 'draft', 403);
        $po->delete();

        return redirect('/vms/pos')->with('status', '草稿已删除');
    }

    public function export(PurchaseOrder $po)
    {
        $this->mine($po)->load('lines');
        $po->update(['exported_at' => now()]);

        return ExportService::purchaseOrders(collect([$po]), "PO-{$po->draft_no}.xlsx");
    }
}
