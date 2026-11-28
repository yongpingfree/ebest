<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

/** /vms 供应商端支持中英文切换(会话保存);/vms/staff 固定中文。翻译以中文原文为键,见 lang/en.json */
class SetVmsLocale
{
    public const LOCALES = ['zh', 'en'];

    public function handle(Request $request, Closure $next)
    {
        $locale = 'zh';
        if (! $request->is('vms/staff', 'vms/staff/*')) {
            $pick = $request->session()->get('vms_locale') ?? $request->cookie('vms_locale');
            if (in_array($pick, self::LOCALES, true)) {
                $locale = $pick;
            }
        }
        app()->setLocale($locale);
        // 中文是源语言:找不到翻译时原样显示中文,不能回退到英文
        app('translator')->setFallback('zh');

        return $next($request);
    }
}
