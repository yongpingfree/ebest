<?php

namespace App\Http\Controllers;

use App\Mail\VerificationCodeMail;
use App\Models\Vendor;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;

class VendorAuthController extends Controller
{
    public function showRegister()
    {
        return view('auth.register');
    }

    public function register(Request $r)
    {
        $data = $r->validate([
            'email' => ['required', 'email:rfc', 'max:190', 'unique:vendors,email'],
            'password' => ['required', 'string', 'min:10', 'confirmed'],
        ], ['email.unique' => __('该邮箱已注册,请直接登录'), 'password.min' => __('密码至少 10 位')]);

        $vendor = Vendor::create(['email' => strtolower($data['email']), 'password' => $data['password']]);
        $this->sendCode($vendor);
        Auth::guard('vendor')->login($vendor);

        return redirect('/vms/verify')->with('status', __('验证码已发送到 :email', ['email' => $vendor->email]));
    }

    public function showVerify()
    {
        $v = auth('vendor')->user();
        if ($v->email_verified_at) {
            return redirect('/vms/dashboard');
        }

        return view('auth.verify', ['vendor' => $v]);
    }

    public function verify(Request $r)
    {
        $v = auth('vendor')->user();
        $r->validate(['code' => ['required', 'digits:6']], ['code.digits' => __('验证码为 6 位数字')]);

        if ($v->verification_attempts >= config('vms.verification_max_attempts')) {
            return back()->withErrors(['code' => __('错误次数过多,请重新获取验证码')]);
        }
        if (! $v->verification_code || ! $v->verification_expires_at || $v->verification_expires_at->isPast()) {
            return back()->withErrors(['code' => __('验证码已过期,请重新获取')]);
        }
        if (! Hash::check($r->code, $v->verification_code)) {
            $v->increment('verification_attempts');

            return back()->withErrors(['code' => __('验证码不正确')]);
        }
        $v->update(['email_verified_at' => now(), 'verification_code' => null, 'verification_expires_at' => null, 'verification_attempts' => 0]);

        return redirect('/vms/profile')->with('status', __('邮箱验证成功,请填写供应商注册资料'));
    }

    public function resend()
    {
        $v = auth('vendor')->user();
        if ($v->verification_expires_at && $v->verification_expires_at->gt(now()->addMinutes(config('vms.verification_ttl_minutes') - 1))) {
            return back()->withErrors(['code' => __('请等待 1 分钟后再重新获取')]);
        }
        $this->sendCode($v);

        return back()->with('status', __('验证码已重新发送'));
    }

    public function showLogin()
    {
        return view('auth.login');
    }

    public function login(Request $r)
    {
        $cred = $r->validate(['email' => ['required', 'email'], 'password' => ['required']]);
        $cred['email'] = strtolower($cred['email']);
        if (! Auth::guard('vendor')->attempt($cred, $r->boolean('remember'))) {
            return back()->withErrors(['email' => __('邮箱或密码不正确')])->onlyInput('email');
        }
        $r->session()->regenerate();

        return redirect('/vms/dashboard');
    }

    public function logout(Request $r)
    {
        Auth::guard('vendor')->logout();
        $r->session()->invalidate();
        $r->session()->regenerateToken();

        return redirect('/vms/login');
    }

    private function sendCode(Vendor $v): void
    {
        $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        $ttl = (int) config('vms.verification_ttl_minutes');
        $v->update(['verification_code' => Hash::make($code), 'verification_expires_at' => now()->addMinutes($ttl), 'verification_attempts' => 0]);
        Mail::to($v->email)->send(new VerificationCodeMail($code, $ttl));
    }
}
