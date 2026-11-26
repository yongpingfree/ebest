<?php

namespace App\Http\Controllers;

use App\Models\Vendor;
use App\Models\VendorHistory;
use Illuminate\Http\Request;

class ProfileController extends Controller
{
    public function show()
    {
        $v = auth('vendor')->user();

        return view('profile', ['vendor' => $v, 'maskedAccount' => Vendor::maskAccount($v->account_number)]);
    }

    public function update(Request $r)
    {
        $v = auth('vendor')->user();
        if ($v->status === 'pending' || ($v->isApproved() && $v->pending_changes)) {
            return back()->with('warning', '资料正在审核中,暂不能修改');
        }
        $data = $r->validate([
            'application_type' => ['required', 'in:new,amend'],
            'abn' => ['required', 'regex:/^\d{11}$/'],
            'name' => ['required', 'string', 'max:190'],
            'street_address' => ['required', 'string', 'max:255'],
            'postal_address' => ['required', 'string', 'max:255'],
            'phone' => ['required', 'string', 'max:40'],
            'payment_terms_days' => ['required', 'integer', 'min:0', 'max:365'],
            'bsb' => ['required', 'regex:/^\d{3}-?\d{3}$/'],
            'account_number' => ['nullable', 'regex:/^\d{4,10}$/'],
            'bank_institution' => ['required', 'string', 'max:120'],
            'bank_branch' => ['required', 'string', 'max:120'],
            'bank_account_name' => ['required', 'string', 'max:190'],
            'contact_name' => ['required', 'string', 'max:120'],
            'contact_phone' => ['required', 'string', 'max:40'],
            'auth_confirmed' => ['accepted'],
            'auth_name' => ['required', 'string', 'max:120'],
            'auth_phone' => ['required', 'string', 'max:40'],
        ], [
            'abn.regex' => '澳大利亚商业号(ABN)须为 11 位数字',
            'bsb.regex' => 'BSB 格式为 6 位数字(如 082-001)',
            'account_number.regex' => '银行账号须为 4–10 位数字',
            'auth_confirmed.accepted' => '请勾选授权声明',
        ], [
            'abn' => '澳大利亚商业号', 'name' => '供应商名称', 'street_address' => '街道地址', 'postal_address' => '邮寄地址',
            'phone' => '电话', 'payment_terms_days' => '付款期限', 'bsb' => 'BSB', 'account_number' => '银行账号',
            'bank_institution' => '金融机构', 'bank_branch' => '分行名称', 'bank_account_name' => '账户名称',
            'contact_name' => '联系人姓名', 'contact_phone' => '联系人电话', 'auth_name' => '填写人姓名', 'auth_phone' => '填写人电话',
        ]);
        $data['abn'] = preg_replace('/\D/', '', $data['abn']);
        $data['bsb'] = strlen($data['bsb']) === 6 ? substr($data['bsb'], 0, 3).'-'.substr($data['bsb'], 3) : $data['bsb'];
        $data['auth_confirmed'] = true;
        $data['auth_date'] = today();
        if (empty($data['account_number'])) {
            if (! $v->account_number) {
                return back()->withErrors(['account_number' => '请填写银行账号'])->withInput();
            }
            unset($data['account_number']); // 留空表示不修改
        }

        $warn = null;
        if (mb_strtolower(trim($data['bank_account_name'])) !== mb_strtolower(trim($data['name']))) {
            $warn = '提示:账户名称与供应商名称不一致,审核时运营会进一步核实。';
        }

        if ($v->isApproved()) {
            // 已通过的供应商修改资料须重新审核;审核通过前保留原资料并继续可用(FR-8.9)
            if (isset($data['account_number'])) {
                $data['account_number'] = \Illuminate\Support\Facades\Crypt::encryptString($data['account_number']);
            }
            $data['auth_date'] = $data['auth_date']->toDateString();
            $v->update(['pending_changes' => $data, 'application_type' => 'amend', 'submitted_at' => now(), 'reject_reason' => null]);
            $event = '提交资料修改申请';
        } else {
            $v->update($data + ['status' => 'pending', 'submitted_at' => now(), 'reject_reason' => null]);
            $event = '提交注册资料';
        }
        VendorHistory::create(['vendor_id' => $v->id, 'event' => $event, 'actor' => $v->email]);

        return redirect('/vms/profile')->with('status', '资料已提交,等待 eBest 审核。')->with('warning', $warn);
    }
}
