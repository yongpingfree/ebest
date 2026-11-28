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

    /** 邮件通知 eBest 审核人。收件人:VMS_STAFF_NOTIFY_EMAIL(逗号分隔),未配置则发给全部启用的管理员;发送失败只记日志 */
    private function notifyStaff(Vendor $v, bool $amend): void
    {
        $to = array_filter(array_map('trim', explode(',', (string) config('vms.staff_notify_email'))));
        if (! $to) {
            $to = \App\Models\StaffUser::where('role', 'admin')->where('is_active', true)->pluck('email')->all();
        }
        if (! $to) {
            return;
        }
        try {
            \Illuminate\Support\Facades\Mail::to($to)->send(new \App\Mail\VendorSubmittedMail($v, $amend));
            $v->update(['submit_notified_at' => now()]);
        } catch (\Throwable $e) {
            report($e);
        }
    }

    public function update(Request $r)
    {
        $v = auth('vendor')->user();
        if ($v->status === 'pending' || ($v->isApproved() && $v->pending_changes)) {
            return back()->with('warning', __('资料正在审核中,暂不能修改'));
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
            'abn.regex' => __('澳大利亚商业号(ABN)须为 11 位数字'),
            'bsb.regex' => __('BSB 格式为 6 位数字(如 082-001)'),
            'account_number.regex' => __('银行账号须为 4–10 位数字'),
            'auth_confirmed.accepted' => __('请勾选授权声明'),
        ], [
            'abn' => __('澳大利亚商业号'), 'name' => __('供应商名称'), 'street_address' => __('街道地址'), 'postal_address' => __('邮寄地址'),
            'phone' => __('电话'), 'payment_terms_days' => __('付款期限'), 'bsb' => 'BSB', 'account_number' => __('银行账号'),
            'bank_institution' => __('金融机构'), 'bank_branch' => __('分行名称'), 'bank_account_name' => __('账户名称'),
            'contact_name' => __('联系人姓名'), 'contact_phone' => __('联系人电话'), 'auth_name' => __('填写人姓名'), 'auth_phone' => __('填写人电话'),
        ]);
        if (! $v->hasBrandWithImage()) {
            return back()->withErrors(['brand' => __('请至少添加一个品牌并上传品牌图片后再提交')])->withInput();
        }
        $data['abn'] = preg_replace('/\D/', '', $data['abn']);
        $data['bsb'] = strlen($data['bsb']) === 6 ? substr($data['bsb'], 0, 3).'-'.substr($data['bsb'], 3) : $data['bsb'];
        $data['auth_confirmed'] = true;
        $data['auth_date'] = today();
        if (empty($data['account_number'])) {
            if (! $v->account_number) {
                return back()->withErrors(['account_number' => __('请填写银行账号')])->withInput();
            }
            unset($data['account_number']); // 留空表示不修改
        }

        $warn = null;
        if (mb_strtolower(trim($data['bank_account_name'])) !== mb_strtolower(trim($data['name']))) {
            $warn = __('提示:账户名称与供应商名称不一致,审核时运营会进一步核实。');
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
        $this->notifyStaff($v->fresh(), $v->isApproved());

        return redirect('/vms/profile')->with('status', __('资料已提交,等待 eBest 审核。'))->with('warning', $warn);
    }
}
