<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/vms/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->redirectGuestsTo(function ($request) {
            return $request->is('vms/staff/*') ? url('/vms/staff/login') : url('/vms/login');
        });
        $middleware->web(append: [\App\Http\Middleware\SetVmsLocale::class]);
        $middleware->alias([
            'vendor.approved' => \App\Http\Middleware\EnsureVendorApproved::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {})
    ->create();
