<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

/**
 * Anonymous access is allowed only for the official eBest app:
 *   User-Agent starts with "okhttp" AND X-Requested-With == "com.donkibuy.ebest".
 * Every other client must authenticate (Sanctum bearer token or session).
 */
class EnforceAppClientAuth
{
    public const APP_ID = 'com.donkibuy.ebest';

    public function handle(Request $request, Closure $next): Response
    {
        $ua = (string) $request->header('User-Agent', '');
        $isApp = str_starts_with($ua, 'okhttp')
            && $request->header('X-Requested-With') === self::APP_ID;

        if (! $isApp && ! Auth::guard('sanctum')->check()) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        return $next($request);
    }
}
