<?php

namespace App\Http\Controllers;

use App\Models\Item;
use App\Models\PurchaseOrder;

class DashboardController extends Controller
{
    public function index()
    {
        $v = auth('vendor')->user();

        return view('dashboard', [
            'vendor' => $v,
            'itemCounts' => Item::where('vendor_id', $v->id)->selectRaw('status, count(*) c')->groupBy('status')->pluck('c', 'status'),
            'poCounts' => PurchaseOrder::where('vendor_id', $v->id)->selectRaw('status, count(*) c')->groupBy('status')->pluck('c', 'status'),
        ]);
    }
}
