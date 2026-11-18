<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

/**
 * Dispatches /report/{id} to reports/report{id}.php (landing script).
 */
class ReportController extends Controller
{
    public function __invoke(Request $request, int $id)
    {
        $script = base_path("reports/report{$id}.php");

        if (! is_file($script)) {
            abort(404);
        }

        return (require $script)($request);
    }
}
