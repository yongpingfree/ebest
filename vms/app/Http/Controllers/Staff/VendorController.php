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
            if ($r->status === 'amend') {
                $q->whereNotNull('pending_changes');
            } elseif ($r->status === 'pending') {
                // 待审核 = 新注册待审(status=pending) + 已通过供应商提交的资料修改(status 仍为 approved,但有 pending_changes)
                $q->where(fn ($x) => $x->where('status', 'pending')->orWhereNotNull('pending_changes'));
            } else {
                $q->where('status', $r->status);
            }
        }
        if ($r->filled('q')) {
            $q->where(fn ($x) => $x->where('name', 'like', "%{$r->q}%")->orWhere('email', 'like', "%{$r->q}%")->orWhere('abn', 'like', "%{$r->q}%"));
        }

        return view('staff.vendors.index', ['vendors' => $q->paginate(30)->withQueryString()]);
    }

    public function show(Vendor $vendor)
    {
        $vendor->load('histories', 'brands');

        return view('staff.vendors.show', ['vendor' => $vendor, 'full' => false, 'accountMasked' => Vendor::maskAccount($vendor->account_number)]);
    }

    /** 查看完整银行信息:仅管理员,并记录审计日志(FR-8.10) */
    public function reveal(Vendor $vendor)
    {
        $staff = auth('staff')->user();
        abort_unless($staff->isAdmin(), 403, '仅管理员可查看完整银行信息');
        AuditLog::record($staff->email, 'view_bank_details', "vendor:{$vendor->id}", $vendor->name);
        $vendor->load('histories', 'brands');

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

    /** 单个供应商导出(兼容旧入口) */
    public function wmsExport(Vendor $vendor)
    {
        return $this->exportVendors(collect([$vendor]));
    }

    /** 多选导出:每个供应商一行,最后一行是可直接在 WMS 数据库执行的 suppliers 表 INSERT 语句。含银行账号,仅管理员,记录审计 */
    public function export(Request $r)
    {
        $ids = array_filter((array) $r->input('ids', []));
        abort_if(! $ids, 422, '请至少选择一个供应商');

        return $this->exportVendors(Vendor::whereIn('id', $ids)->orderBy('id')->get());
    }

    private function exportVendors($vendors)
    {
        $staff = auth('staff')->user();
        abort_unless($staff->isAdmin(), 403, '仅管理员可导出完整银行信息');
        abort_if($vendors->isEmpty(), 404);
        foreach ($vendors as $v) {
            AuditLog::record($staff->email, 'export_wms_vendor_fields', "vendor:{$v->id}", $v->name);
        }
        $rows = [['供应商名称', '简称', '商业号', '银行账户名称', '银行名称', '分行代码', '账号', '付款期限', 'WMS 对应关系']];
        foreach ($vendors as $v) {
            $rows[] = [$v->name, $v->short_name, $v->abn, $v->bank_account_name, $v->bank_institution, $v->bsb, $v->account_number, $v->payment_terms_days, $v->wms_vendor_ref];
        }
        $rows[] = [$this->suppliersInsertSql($vendors)]; // 最后一条记录:建档 SQL

        return response()->streamDownload(function () use ($rows) {
            $f = fopen('php://output', 'w');
            fwrite($f, "\xEF\xBB\xBF");
            foreach ($rows as $row) {
                fputcsv($f, $row);
            }
            fclose($f);
        }, 'wms-vendors-'.now()->format('Ymd-His').'.csv', ['Content-Type' => 'text/csv; charset=UTF-8']);
    }

    /** 对应 WMS suppliers 表(见 issues/wms_suppliers.sql)的 INSERT;单引号与反斜杠已转义 */
    private function suppliersInsertSql($vendors): string
    {
        $q = fn ($v) => $v === null || $v === '' ? 'NULL' : "'".str_replace(["\\", "'"], ["\\\\", "''"], (string) $v)."'";
        $values = [];
        foreach ($vendors as $v) {
            $values[] = '('.implode(', ', [
                (int) config('vms.store_id'), $q($v->name), $q($v->short_name), $q($v->abn), $q($v->bank_account_name),
                $q($v->bank_institution), $q($v->bsb), $q($v->account_number),
                $v->payment_terms_days === null ? 'NULL' : (int) $v->payment_terms_days, 'NOW()', 'NOW()',
            ]).')';
        }

        return 'INSERT INTO `suppliers` (`websites_id`, `supplier_name`, `supplier_short_name`, `supplier_abn`, `bank_acc_name`, `bank_name`, `bank_bsb`, `bank_acc_number`, `payment_term`, `created_at`, `updated_at`) VALUES '.implode(', ', $values).';';
    }
}
