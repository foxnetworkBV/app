<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class FoxNetworkMobileAccess
{
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();
        $token = $user?->token();
        $clientId = (string) config('foxnetwork.client_id');
        // Do not grant access to arbitrary third-party profile tokens.
        abort_unless($clientId !== '' && $token &&
            (string) $token->client_id === $clientId && $user->tokenCan('profile') &&
            $user->tokenCan('foxnetwork:customer'), 403);
        if ($request->path() !== 'api/foxnetwork/logout') {
            abort_if(config('settings.mail_must_verify', false) && !$user->email_verified_at,
                403, 'Verify your email address in the customer portal first.');
        }
        $response = $next($request);
        $response->headers->set('Cache-Control', 'no-store, private');
        return $response;
    }
}
