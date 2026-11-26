<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

/** 邮箱已验证且资料审核通过的供应商才能进入商品和采购单 */
class EnsureVendorApproved
{
    public function handle(Request $request, Closure $next)
    {
        $v = auth('vendor')->user();
        if (! $v->email_verified_at) {
            return redirect('/vms/verify')->with('status', '请先完成邮箱验证');
        }
        if (! $v->isApproved()) {
            return redirect('/vms/profile')->with('warning', '供应商资料审核通过后才能录入商品和创建采购单');
        }

        return $next($request);
    }
}
