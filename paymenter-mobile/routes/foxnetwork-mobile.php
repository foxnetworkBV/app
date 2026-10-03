<?php

use App\Http\Controllers\FoxNetworkMobileController as Mobile;
use App\Http\Middleware\FoxNetworkMobileAccess;
use Illuminate\Support\Facades\Route;

Route::get('config', [Mobile::class, 'configuration'])->middleware('throttle:30,1');
Route::middleware(['auth:api', FoxNetworkMobileAccess::class, 'throttle:120,1'])->group(function () {
    Route::get('me', [Mobile::class, 'me']);
    Route::post('logout', [Mobile::class, 'logout']);
    Route::get('services', [Mobile::class, 'services']);
    Route::get('services/{id}/resources', [Mobile::class, 'resources'])->whereNumber('id');
    Route::get('services/{id}/console', [Mobile::class, 'console'])->whereNumber('id');
    Route::post('services/{id}/power', [Mobile::class, 'power'])->whereNumber('id')->middleware('throttle:20,1');
    Route::get('invoices', [Mobile::class, 'invoices']);
    Route::get('invoices/{id}', [Mobile::class, 'invoice'])->whereNumber('id');
    Route::get('tickets', [Mobile::class, 'tickets']);
    Route::get('tickets/{id}', [Mobile::class, 'ticket'])->whereNumber('id');
    Route::post('tickets', [Mobile::class, 'createTicket'])->middleware('throttle:2,1');
});
