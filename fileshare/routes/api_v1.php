<?php

use Illuminate\Support\Facades\Route;
use App\Http\Middleware\EnforceAppClientAuth;

// GET /apptest/api/v1/items/{itemid}
Route::middleware(EnforceAppClientAuth::class)->group(function () {
    Route::get('items/{itemid}', function (string $itemid) {
        $item = json_decode(file_get_contents(resource_path('samples/item.json')), true);
        $item['id'] = ctype_digit($itemid) ? (int) $itemid : $itemid;

        return response()->json($item);
    })->where('itemid', '[0-9]+');
});
