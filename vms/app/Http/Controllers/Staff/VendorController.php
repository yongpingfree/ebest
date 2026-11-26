<?php

namespace App\Http\Controllers\Staff;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\Vendor;
use App\Models\VendorHistory;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Crypt;

class VendorController extends Controller
{
    public function index(Request $r)
    {
        $q = Vendor::latest('id');
        if ($r->filled('status')) {
            $r->status === 'amend' ? $q->whereNotNull('pending_changes') : $q->where('status', $r->status);
        }
        if ($r->filled('q')) {
            $q->where(fn ($x) => $x->where('name', 'like', "%{$r->q}%")->orWhere('email', 'like', "%{$r->q}%")->orWhere('abn', 'like', "%{$r->q}%"));
        }

        return view('staff.vendors.index', ['vendors' => $q->paginate(30)->withQueryString()]);
    }

    public function show(Vendor $vendor)
    {
        $vendor->load('histories');

        return view('staff.vendors.show', ['vendor' => $vendor, 'full' => false, 'accountMasked' => Vendor::maskAccount($vendor->account_number)]);
    }

    /** 查看完整银行信息:仅管理员,并记录审计日志(FR-8.10) */
    public function reveal(Vendor $vendor)
    {
        $staff = auth('staff')->user();
        abort_unless($staff->isAdmin(), 403, '仅管理员可查看完整银行信息');
        AuditLog::record($staff->email, 'view_bank_details', "vendor:{$vendor->id}", $vendor->name);
        $vendor->load('histories');

        return view('staff.vendors.show', ['vendor' => $vendor, 'full' => true, 'accountMasked' => $vendor->account_number]);
    }

    public function approve(Request $r, Vendor $vendor)
    {
        $staff = auth('staff')->user();
        $data = $r->validate(['short_name' => ['nullable', 'string', 'max:60'], 'wms_vendor_ref' => ['nullable', 'string', 'max:120']]);
        $event = '审核通过';
        if ($vendor->isApproved() && $vendor->pending_changes) {
            $changes = $vendor->pending_changes;
            if (isset($changes['account_number'])) {
                $changes['account_number'] = Crypt::decryptString($changes['account_number']);
            }
            AuditLog::record($staff->email, 'amend_vendor', "vendor:{$vendor->id}", '资料修改已批准');
            $vendor->update($changes + ['pending_changes' => null, 'application_type' => 'new']);
            $event = '资料修改审核通过';
        }
        $vendor->update(array_filter($data) + ['status' => 'approved', 'reviewed_at' => now(), 'reject_reason' => null]);
        VendorHistory::create(['vendor_id' => $vendor->id, 'event' => $event, 'note' => '请运营在 WMS 供应商管理中建档并回填对应关系', 'actor' => $staff->email]);

        return back()->with('status', '已通过。请在 WMS 建立供应商后,回填 WMS 对应关系。');
    }

    public function reject(Request $r, Vendor $vendor)
    {
        $r->validate(['reason' => ['required', 'string', 'max:1000']], ['reason.required' => '驳回时必须填写原因']);
        $staff = auth('staff')->user();
        if ($vendor->isApproved()) {
            $vendor->update(['pending_changes' => null, 'reject_reason' => $r->reason]);
        } else {
            $vendor->update(['status' => 'rejected', 'reviewed_at' => now(), 'reject_reason' => $r->reason]);
        }
        VendorHistory::create(['vendor_id' => $vendor->id, 'event' => '已驳回', 'note' => $r->reason, 'actor' => $staff->email]);

        return back()->with('status', '已驳回,供应商可修改后重新提交。');
    }

    public function setWmsRef(Request $r, Vendor $vendor)
    {
        $d = $r->validate(['wms_vendor_ref' => ['required', 'string', 'max:120'], 'short_name' => ['nullable', 'string', 'max:60']]);
        $vendor->update(array_filter($d));
        VendorHistory::create(['vendor_id' => $vendor->id, 'event' => '回填 WMS 供应商对应关系', 'note' => $d['wms_vendor_ref'], 'actor' => auth('staff')->user()->email]);

        return back()->with('status', '已记录 WMS 对应关系,供应商现可使用。');
    }

    /** 提供 WMS 供应商管理建档所需字段(FR-8.7)。包含银行账号,仅管理员,记录审计 */
    public function wmsExport(Vendor $vendor)
    {
        $staff = auth('staff')->user();
        abort_unless($staff->isAdmin(), 403, '仅管理员可导出完整银行信息');
        AuditLog::record($staff->email, 'export_wms_vendor_fields', "vendor:{$vendor->id}", $vendor->name);
        $rows = [
            ['供应商名称', '简称', '商业号', '银行账户名称', '银行名称', '分行代码', '账号', '付款期限'],
            [$vendor->name, $vendor->short_name, $vendor->abn, $vendor->bank_account_name, $vendor->bank_institution, $vendor->bsb, $vendor->account_number, $vendor->payment_terms_days],
        ];

        return response()->streamDownload(function () use ($rows) {
            $f = fopen('php://output', 'w');
            fwrite($f, "\xEF\xBB\xBF");
            foreach ($rows as $row) {
                fputcsv($f, $row);
            }
            fclose($f);
        }, "wms-vendor-{$vendor->id}.csv", ['Content-Type' => 'text/csv; charset=UTF-8']);
    }
}
