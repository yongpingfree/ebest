<?php

use App\Http\Controllers\DashboardController;
use App\Http\Controllers\ItemController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\PurchaseOrderController;
use App\Http\Controllers\Staff;
use App\Http\Controllers\VendorAuthController;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;

Route::redirect('/', '/vms');

Route::prefix('vms')->group(function () {
    // 静态资源经 Laravel 输出,不依赖 Nginx 是否转发 /vms/css、/vms/images
    Route::get('css/vms.css', fn () => response()->file(public_path('vms/css/vms.css'), ['Content-Type' => 'text/css; charset=utf-8', 'Cache-Control' => 'public, max-age=3600']));
    Route::get('images/{file}', function (string $file) {
        abort_unless(in_array($file, ['ebest.png', 'logo.png'], true), 404);
        return response()->file(public_path('vms/images/'.$file), ['Cache-Control' => 'public, max-age=86400']);
    });

    // 本地(public 盘)图片经 Laravel 输出,不依赖 storage:link 和 Nginx 配置;生产用 S3/CDN 时不经过这里
    Route::get('storage/{path}', function (string $path) {
        abort_unless(str_starts_with($path, 'images/') && ! str_contains($path, '..'), 404);
        $disk = Storage::disk('public');
        abort_unless($disk->exists($path), 404);

        return response()->file($disk->path($path), ['Cache-Control' => 'public, max-age=86400']);
    })->where('path', '.*');

    Route::get('/', fn () => auth('vendor')->check() ? redirect('/vms/dashboard') : redirect('/vms/login'));

    // ---- 供应商:注册 / 登录 / 邮箱验证 ----
    Route::middleware('guest:vendor')->group(function () {
        Route::get('register', [VendorAuthController::class, 'showRegister']);
        Route::post('register', [VendorAuthController::class, 'register'])->middleware('throttle:10,1');
        Route::get('login', [VendorAuthController::class, 'showLogin'])->name('login');
        Route::post('login', [VendorAuthController::class, 'login'])->middleware('throttle:10,1');
    });

    Route::middleware('auth:vendor')->group(function () {
        Route::post('logout', [VendorAuthController::class, 'logout']);
        Route::get('verify', [VendorAuthController::class, 'showVerify']);
        Route::post('verify', [VendorAuthController::class, 'verify'])->middleware('throttle:10,1');
        Route::post('verify/resend', [VendorAuthController::class, 'resend'])->middleware('throttle:3,1');

        Route::get('dashboard', [DashboardController::class, 'index']);
        Route::get('profile', [ProfileController::class, 'show']);
        Route::post('profile', [ProfileController::class, 'update']);

        Route::middleware('vendor.approved')->group(function () {
            Route::get('items/export', [ItemController::class, 'export']);
            Route::post('items/export', [ItemController::class, 'export']);
            Route::resource('items', ItemController::class)->except(['show'])->parameters(['items' => 'item']);
            Route::get('items/{item}', [ItemController::class, 'show']);
            Route::post('items/{item}/submit', [ItemController::class, 'submit']);
            Route::post('items/{item}/images', [ItemController::class, 'uploadImage']);
            Route::delete('items/{item}/images/{image}', [ItemController::class, 'deleteImage']);

            Route::resource('pos', PurchaseOrderController::class)->except(['show'])->parameters(['pos' => 'po']);
            Route::get('pos/{po}', [PurchaseOrderController::class, 'show']);
            Route::post('pos/{po}/submit', [PurchaseOrderController::class, 'submit']);
            Route::get('pos/{po}/export', [PurchaseOrderController::class, 'export']);
        });
    });

    // ---- eBest 员工 ----
    Route::prefix('staff')->group(function () {
        Route::middleware('guest:staff')->group(function () {
            Route::get('login', [Staff\AuthController::class, 'showLogin']);
            Route::post('login', [Staff\AuthController::class, 'login'])->middleware('throttle:10,1');
        });
        Route::middleware('auth:staff')->group(function () {
            Route::post('logout', [Staff\AuthController::class, 'logout']);
            Route::get('/', [Staff\AuthController::class, 'dashboard']);

            Route::get('vendors', [Staff\VendorController::class, 'index']);
            Route::get('vendors/{vendor}', [Staff\VendorController::class, 'show']);
            Route::get('vendors/{vendor}/reveal', [Staff\VendorController::class, 'reveal']);
            Route::get('vendors/{vendor}/wms-export', [Staff\VendorController::class, 'wmsExport']);
            Route::post('vendors/{vendor}/approve', [Staff\VendorController::class, 'approve']);
            Route::post('vendors/{vendor}/reject', [Staff\VendorController::class, 'reject']);
            Route::post('vendors/{vendor}/wms-ref', [Staff\VendorController::class, 'setWmsRef']);

            Route::get('items', [Staff\ItemController::class, 'index']);
            Route::match(['get', 'post'], 'items/export', [Staff\ItemController::class, 'export']);
            Route::get('items/{item}', [Staff\ItemController::class, 'show']);
            Route::post('items/{item}/ops', [Staff\ItemController::class, 'updateOps']);
            Route::post('items/{item}/return', [Staff\ItemController::class, 'returnItem']);
            Route::post('items/{item}/mark/{to}', [Staff\ItemController::class, 'mark']);

            Route::get('pos', [Staff\PurchaseOrderController::class, 'index']);
            Route::match(['get', 'post'], 'pos/export', [Staff\PurchaseOrderController::class, 'export']);
            Route::get('pos/{po}', [Staff\PurchaseOrderController::class, 'show']);
            Route::post('pos/{po}/wms-no', [Staff\PurchaseOrderController::class, 'setWmsNo']);
            Route::post('pos/{po}/review', [Staff\PurchaseOrderController::class, 'review']);
        });
    });
});
