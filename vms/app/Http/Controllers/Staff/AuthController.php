<?php

namespace App\Http\Controllers\Staff;

use App\Http\Controllers\Controller;
use App\Models\Item;
use App\Models\PurchaseOrder;
use App\Models\Vendor;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AuthController extends Controller
{
    public function showLogin()
    {
        return view('staff.login');
    }

    public function login(Request $r)
    {
        $cred = $r->validate(['email' => ['required', 'email'], 'password' => ['required']]);
        if (! Auth::guard('staff')->attempt($cred + ['is_active' => true], $r->boolean('remember'))) {
            return back()->withErrors(['email' => '邮箱或密码不正确'])->onlyInput('email');
        }
        $r->session()->regenerate();

        return redirect('/vms/staff');
    }

    public function logout(Request $r)
    {
        Auth::guard('staff')->logout();
        $r->session()->invalidate();
        $r->session()->regenerateToken();

        return redirect('/vms/staff/login');
    }

    public function dashboard()
    {
        return view('staff.dashboard', [
            'vendorsPending' => Vendor::where('status', 'pending')->orWhereNotNull('pending_changes')->count(),
            'itemsSubmitted' => Item::where('status', 'submitted')->count(),
            'itemsImported' => Item::where('status', 'imported')->count(),
            'posSubmitted' => PurchaseOrder::where('status', 'submitted')->count(),
            'posException' => PurchaseOrder::where('status', 'exception')->count(),
        ]);
    }
}
