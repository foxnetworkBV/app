<?php

namespace App\Providers;

use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;
use Laravel\Passport\Passport;

class FoxNetworkMobileServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        $this->app->booted(function () {
            $scopes = Passport::scopes()->mapWithKeys(fn ($scope) => [$scope->id => $scope->description])->all();
            Passport::tokensCan(array_merge($scopes, [
                'foxnetwork:customer' => 'View your services and invoices, create support tickets, and control your linked servers',
            ]));
        });
        if (!$this->app->routesAreCached()) {
            Route::middleware('api')->prefix('api/foxnetwork')
                ->group(base_path('routes/foxnetwork-mobile.php'));
        }
    }
}
