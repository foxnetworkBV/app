<?php

namespace App\Http\Controllers;

use App\Models\Invoice;
use App\Models\Service;
use App\Models\Ticket;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Validation\Rule;
use Laravel\Passport\Passport;
use Laravel\Passport\RefreshTokenRepository;
use Laravel\Passport\TokenRepository;

class FoxNetworkMobileController extends Controller
{
    public function configuration()
    {
        $id = (string) config('foxnetwork.client_id');
        $client = $id !== '' ? Passport::client()->find($id) : null;
        abort_unless($client && !$client->revoked && !$client->confidential(), 503,
            'Mobile sign-in is not configured yet. Please contact support.');
        return response()->json(['client_id' => $id, 'version' => 1])
            ->header('Cache-Control', 'no-store');
    }

    public function me(Request $request)
    {
        $user = $request->user();
        return response()->json(['data' => ['id' => $user->id, 'name' => $user->name, 'email' => $user->email]]);
    }

    public function logout(Request $request)
    {
        $id = $request->user()->token()->id;
        app(RefreshTokenRepository::class)->revokeRefreshTokensByAccessTokenId($id);
        app(TokenRepository::class)->revokeAccessToken($id);
        return response()->json(['message' => 'Signed out']);
    }

    private function canControl(Service $service): bool
    {
        $map = config('foxnetwork.server_map', []);
        return $service->status === Service::STATUS_ACTIVE &&
            $service->product?->server?->extension === 'Pterodactyl' &&
            !empty(config('foxnetwork.panel_client_key')) &&
            isset($map[$service->id]) && preg_match('/^[a-zA-Z0-9-]+$/', (string) $map[$service->id]);
    }

    public function services(Request $request)
    {
        $page = $request->user()->services()->with(['product.category', 'product.server'])->orderByDesc('id')->paginate(50);
        $page->getCollection()->transform(fn ($service) => [
            'id' => $service->id, 'name' => $service->label,
            'product' => $service->product?->name ?? 'Service',
            'category' => $service->product?->category?->name ?? 'Other',
            'status' => $service->status, 'hostname' => '',
            'renewal_date' => $service->expires_at?->toIso8601String() ?? '',
            'price' => (float) $service->price * $service->quantity,
            'currency' => $service->currency_code,
            'can_control' => (bool) $this->canControl($service),
            'web_url' => url('/services/' . $service->id),
        ]);
        return response()->json($page);
    }

    private function invoiceData(Invoice $invoice, bool $detail = false): array
    {
        $data = [
            'id' => $invoice->id, 'number' => $invoice->number ?? ('Invoice #' . $invoice->id),
            'status' => $invoice->status, 'currency' => $invoice->currency_code,
            'amount' => (float) $invoice->total, 'total' => (float) $invoice->total,
            'issued_at' => $invoice->created_at?->toIso8601String() ?? '',
            'due_at' => $invoice->due_at?->toIso8601String() ?? '',
            'updated_at' => $invoice->updated_at?->toIso8601String() ?? '',
            'web_url' => url('/invoices/' . $invoice->id),
        ];
        if ($detail) {
            $data['items'] = $invoice->items->map(fn ($item) => [
                'id' => $item->id, 'description' => $item->description,
                'quantity' => (float) $item->quantity, 'price' => (float) $item->price,
                'total' => round((float) $item->price * $item->quantity, 2),
                'currency' => $invoice->currency_code,
            ])->values();
        }
        return $data;
    }

    public function invoices(Request $request)
    {
        $page = $request->user()->invoices()->with('items')->orderByDesc('id')->paginate(50);
        $page->getCollection()->transform(fn ($invoice) => $this->invoiceData($invoice));
        return response()->json($page);
    }

    public function invoice(Request $request, int $id)
    {
        $invoice = $request->user()->invoices()->with('items')->findOrFail($id);
        return response()->json(['data' => $this->invoiceData($invoice, true)]);
    }

    private function ticketData(Ticket $ticket, bool $detail = false): array
    {
        $data = [
            'id' => $ticket->id, 'subject' => $ticket->subject, 'status' => $ticket->status,
            'priority' => $ticket->priority, 'department' => $ticket->department,
            'created_at' => $ticket->created_at?->toIso8601String() ?? '',
            'updated_at' => $ticket->updated_at?->toIso8601String() ?? '',
            'web_url' => url('/tickets/' . $ticket->id),
        ];
        if ($detail) {
            $data['messages'] = $ticket->messages->sortBy('id')->map(fn ($message) => [
                'id' => $message->id, 'message' => $message->message,
                'author' => $message->user?->name ?? 'Support',
                'is_staff' => $message->user_id !== $ticket->user_id,
                'created_at' => $message->created_at?->toIso8601String() ?? '',
            ])->values();
        }
        return $data;
    }

    private function requireTickets(): void
    {
        abort_if(config('settings.tickets_disabled', false), 403, 'Support tickets are disabled. Please contact support by email.');
    }

    public function tickets(Request $request)
    {
        $this->requireTickets();
        $page = $request->user()->tickets()->orderByDesc('id')->paginate(50);
        $page->getCollection()->transform(fn ($ticket) => $this->ticketData($ticket));
        return response()->json($page);
    }

    public function ticket(Request $request, int $id)
    {
        $this->requireTickets();
        $ticket = $request->user()->tickets()->with('messages.user')->findOrFail($id);
        return response()->json(['data' => $this->ticketData($ticket, true)]);
    }

    public function createTicket(Request $request)
    {
        $this->requireTickets();
        $data = $request->validate(['subject' => 'required|string|max:190', 'message' => 'required|string|max:20000']);
        $key = 'create-ticket:' . $request->user()->id;
        abort_if(RateLimiter::tooManyAttempts($key, 1), 429, 'Please wait 30 seconds before opening another ticket.');
        RateLimiter::hit($key, 30);
        $ticket = DB::transaction(function () use ($request, $data) {
            $departments = array_values((array) config('settings.ticket_departments', []));
            $ticket = $request->user()->tickets()->create([
                'subject' => $data['subject'], 'priority' => 'medium',
                'department' => $departments[0] ?? 'Support',
            ]);
            $ticket->messages()->create(['user_id' => $request->user()->id, 'message' => $data['message']]);
            return $ticket;
        });
        return response()->json(['data' => $this->ticketData($ticket->fresh())], 201);
    }

    private function panel(Request $request, int $id, string $endpoint, ?array $body = null): array
    {
        // Resolve ownership before reading any panel mapping or making a request.
        $service = $request->user()->services()->findOrFail($id);
        abort_unless($this->canControl($service), 409, 'Manage this service through the customer portal.');
        $host = rtrim((string) config('foxnetwork.panel_url'), '/');
        abort_unless(parse_url($host, PHP_URL_SCHEME) === 'https', 503, 'Secure panel access is not configured.');
        $identifier = config('foxnetwork.server_map')[$service->id];
        $http = Http::withToken(config('foxnetwork.panel_client_key'))->acceptJson()->timeout(20);
        $url = $host . '/api/client/servers/' . rawurlencode($identifier) . '/' . $endpoint;
        try {
            $response = $body === null ? $http->get($url) : $http->post($url, $body);
        } catch (\Illuminate\Http\Client\ConnectionException $error) {
            abort(502, 'The service panel is temporarily unavailable.');
        }
        abort_unless($response->successful(), 502, 'The service panel could not complete this request.');
        if ($body !== null) return [];
        $attributes = $response->json('attributes');
        abort_unless(is_array($attributes), 502, 'The service panel returned an invalid response.');
        return $attributes;
    }

    public function resources(Request $request, int $id)
    {
        return response()->json(['data' => $this->panel($request, $id, 'resources')]);
    }
    public function power(Request $request, int $id)
    {
        $data = $request->validate(['action' => ['required', Rule::in(['start', 'stop', 'restart', 'kill'])]]);
        $this->panel($request, $id, 'power', ['signal' => $data['action']]);
        return response()->json(['message' => 'Command sent']);
    }
    public function console(Request $request, int $id)
    {
        $data = $this->panel($request, $id, 'websocket');
        return response()->json(['data' => [
            'socket' => $data['socket'] ?? '', 'token' => $data['token'] ?? '', 'server' => (string) $id,
        ]]);
    }
}
