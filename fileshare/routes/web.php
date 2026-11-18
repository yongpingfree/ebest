<?php

use Illuminate\Support\Facades\Route;

use App\Http\Controllers\AdminUploadController;
use App\Http\Controllers\BulkDownloadController;
use App\Http\Controllers\FileDownloadController;
use App\Http\Controllers\ReportController;

Route::get('/files/{file}/download', FileDownloadController::class)
    ->middleware('auth')
    ->name('files.download');
Route::get('/', function () {
    return view('welcome');
});

Route::post('/admin-upload', AdminUploadController::class)
    ->middleware('auth')
    ->name('admin.upload');

Route::post('/files/download-selected', BulkDownloadController::class)
    ->middleware('auth')
    ->name('files.bulk');

Route::get('/report/{id}', ReportController::class)
    ->whereNumber('id')
    ->name('report');
