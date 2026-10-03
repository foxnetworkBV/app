<?php

namespace Tests\Feature;

use App\Models\Invoice;
use App\Models\Ticket;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Laravel\Passport\Token;
use Tests\TestCase;

class FoxNetworkMobileTest extends TestCase
{
    use RefreshDatabase;

    private function customer(User $user, string $client = 'mobile-test', array $scopes = ['profile', 'foxnetwork:customer']): void
    {
        config(['foxnetwork.client_id' => 'mobile-test', 'settings.mail_must_verify' => false, 'settings.tickets_disabled' => false]);
        $user->withAccessToken(new Token(['client_id' => $client, 'scopes' => $scopes]));
        $this->actingAs($user, 'api');
    }

    public function test_anonymous_customer_requests_are_rejected(): void
    {
        $this->getJson('/api/foxnetwork/me')->assertUnauthorized();
    }

    public function test_other_oauth_clients_and_insufficient_scopes_are_rejected(): void
    {
        $user = User::factory()->create();
        $this->customer($user, 'unrelated-client');
        $this->getJson('/api/foxnetwork/me')->assertForbidden();
        $this->customer($user, 'mobile-test', ['profile']);
        $this->getJson('/api/foxnetwork/me')->assertForbidden();
    }

    public function test_email_verification_setting_is_enforced(): void
    {
        $user = User::factory()->create(['email_verified_at' => null]);
        $this->customer($user);
        config(['settings.mail_must_verify' => true]);
        $this->getJson('/api/foxnetwork/me')->assertForbidden();
    }

    public function test_customers_cannot_read_another_customers_invoice_or_ticket(): void
    {
        $owner = User::factory()->create();
        $other = User::factory()->create();
        $invoice = Invoice::withoutEvents(fn () => Invoice::factory()->create(['user_id' => $other->id]));
        $ticket = Ticket::withoutEvents(fn () => $other->tickets()->create([
            'subject' => 'Private ticket', 'status' => 'open', 'priority' => 'medium', 'department' => 'Support',
        ]));
        $this->customer($owner);
        $this->getJson('/api/foxnetwork/invoices/' . $invoice->id)->assertNotFound();
        $this->getJson('/api/foxnetwork/tickets/' . $ticket->id)->assertNotFound();
        $this->getJson('/api/foxnetwork/tickets')->assertOk()->assertJsonCount(0, 'data');
        $this->getJson('/api/foxnetwork/invoices')->assertOk()->assertJsonCount(0, 'data');
    }

    public function test_ticket_creation_uses_authenticated_customer_and_persists_message(): void
    {
        $owner = User::factory()->create();
        $other = User::factory()->create();
        $this->customer($owner);
        $response = $this->postJson('/api/foxnetwork/tickets', [
            'subject' => 'Need help', 'message' => 'My hosting needs attention.', 'user_id' => $other->id,
        ])->assertCreated();
        $id = $response->json('data.id');
        $this->assertDatabaseHas('tickets', ['id' => $id, 'user_id' => $owner->id]);
        $this->assertDatabaseHas('ticket_messages', ['ticket_id' => $id, 'user_id' => $owner->id, 'message' => 'My hosting needs attention.']);
    }

    public function test_missing_service_never_reaches_the_panel(): void
    {
        $this->customer(User::factory()->create());
        Http::fake();
        config(['foxnetwork.panel_client_key' => 'server-only', 'foxnetwork.server_map' => [999999 => 'abc12345']]);
        $this->postJson('/api/foxnetwork/services/999999/power', ['action' => 'start'])->assertNotFound();
        $this->getJson('/api/foxnetwork/services/999999/console')->assertNotFound();
        Http::assertNothingSent();
    }
}
