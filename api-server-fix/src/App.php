<?php

declare(strict_types=1);

namespace FoxNetwork;

use DateTimeImmutable;
use PDO;
use FoxNetwork\Http\Request;
use FoxNetwork\Http\Response;
use FoxNetwork\Integrations\PterodactylClient;
use FoxNetwork\Integrations\PaymenterOAuthClient;
use FoxNetwork\Integrations\PaymenterAdminClient;

final class App
{
    private Auth $auth;

    public function __construct(
        private PDO $db,
        private Config $config
    ) {
        $this->auth = new Auth($db, $config);
        $this->ensureOAuthStatesTable();
        $this->ensureSupportTables();
    }

    private function ensureOAuthStatesTable(): void
    {
        $this->db->exec(
            'CREATE TABLE IF NOT EXISTS oauth_states (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                state_hash TEXT NOT NULL UNIQUE,
                status TEXT NOT NULL DEFAULT \'pending\',
                result_token TEXT NULL,
                result_user_json TEXT NULL,
                error_message TEXT NULL,
                expires_at TEXT NOT NULL,
                created_at TEXT NOT NULL
            )'
        );

        $this->db->exec(
            'CREATE INDEX IF NOT EXISTS oauth_states_expires_at_index
             ON oauth_states (expires_at)'
        );
    }

    private function ensureSupportTables(): void
    {
        $this->db->exec(
            "CREATE TABLE IF NOT EXISTS tickets (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                subject TEXT NOT NULL,
                message TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'Open',
                updated_at TEXT NOT NULL,
                created_at TEXT NOT NULL
            )"
        );
        $this->db->exec('CREATE INDEX IF NOT EXISTS tickets_user_id_index ON tickets (user_id)');
    }

    public function handle(Request $request): never
    {
        $method = $request->method();
        $path = $request->path();

        if ($method === 'GET' && $path === '/api/health') {
            Response::json([
                'status' => 'ok',
                'name' => 'FoxNetwork API',
                'time' => (new DateTimeImmutable())->format(DATE_ATOM),
                'version' => 'paymenter-live-billing-support-4.5',
            ]);
        }

        if ($method === 'GET' && $path === '/api/paymenter/authorize') {
            $this->paymenterAuthorize();
        }

        if ($method === 'GET' && $path === '/api/paymenter/start') {
            $this->paymenterStart($request);
        }

        if ($method === 'GET' && $path === '/api/paymenter/callback') {
            $this->paymenterCallback($request);
        }

        if ($method === 'GET' && $path === '/api/paymenter/status') {
            $this->paymenterStatus($request);
        }

        // Kept for local development only. Real customers use Paymenter OAuth.
        if ($method === 'POST' && $path === '/api/login') {
            $this->login($request);
        }

        if ($method === 'GET' && $path === '/api/me') {
            $user = $this->auth->requireUser($request);
            Response::json($this->publicUser($user));
        }

        if ($method === 'POST' && $path === '/api/logout') {
            $this->auth->requireUser($request);
            $this->auth->deleteToken($request->bearerToken());
            Response::json(['message' => 'Logged out']);
        }

        if ($method === 'GET' && $path === '/api/services') {
            $user = $this->auth->requireUser($request);
            $this->services($user);
        }

        if ($method === 'GET' && $path === '/api/paymenter/debug/services') {
            $user = $this->auth->requireUser($request);
            $client = new PaymenterAdminClient($this->config);
            Response::json($client->diagnostics((int) ($user['paymenter_id'] ?? 0)));
        }

        if ($method === 'POST' && preg_match('#^/api/services/(\d+)/power$#', $path, $matches)) {
            $user = $this->auth->requireUser($request);
            $this->power($request, (int) $user['id'], (int) $matches[1]);
        }

        if ($method === 'GET' && $path === '/api/invoices') {
            $user = $this->auth->requireUser($request);
            $this->invoices($user);
        }

        if ($method === 'GET' && $path === '/api/tickets') {
            $user = $this->auth->requireUser($request);
            $this->tickets($user);
        }

        if ($method === 'POST' && $path === '/api/tickets') {
            $user = $this->auth->requireUser($request);
            $this->createTicket($request, (int) $user['id']);
        }

        Response::json(['message' => 'Endpoint not found'], 404);
    }



    private function paymenterAuthorize(): never
    {
        $state = bin2hex(random_bytes(24));
        $now = new DateTimeImmutable();

        $cleanup = $this->db->prepare('DELETE FROM oauth_states WHERE expires_at <= :now');
        $cleanup->execute(['now' => $now->format(DATE_ATOM)]);

        $statement = $this->db->prepare(
            'INSERT INTO oauth_states (state_hash, status, expires_at, created_at)
             VALUES (:state_hash, :status, :expires_at, :created_at)'
        );
        $statement->execute([
            'state_hash' => hash('sha256', $state),
            'status' => 'pending',
            'expires_at' => $now->modify('+10 minutes')->format(DATE_ATOM),
            'created_at' => $now->format(DATE_ATOM),
        ]);

        $baseUrl = rtrim((string) $this->config->get('APP_URL', 'http://127.0.0.1:8080'), '/');

        Response::json([
            'authorization_url' => $baseUrl . '/api/paymenter/start?state=' . rawurlencode($state),
            'state' => $state,
        ]);
    }

    private function paymenterStart(Request $request): never
    {
        $state = trim((string) $request->query('state', ''));

        if ($state === '') {
            Response::html($this->oauthPage(false, 'Missing login state.'), 422);
        }

        $statement = $this->db->prepare(
            'SELECT id FROM oauth_states
             WHERE state_hash = :state_hash AND expires_at > :now
             LIMIT 1'
        );
        $statement->execute([
            'state_hash' => hash('sha256', $state),
            'now' => (new DateTimeImmutable())->format(DATE_ATOM),
        ]);

        if (!$statement->fetch()) {
            Response::html($this->oauthPage(false, 'This login request expired.'), 422);
        }

        setcookie('foxnetwork_oauth_state', $state, [
            'expires' => time() + 600,
            'path' => '/api/paymenter',
            'secure' => str_starts_with(
                (string) $this->config->get('APP_URL', ''),
                'https://'
            ),
            'httponly' => true,
            'samesite' => 'Lax',
        ]);

        $paymenter = new PaymenterOAuthClient($this->config);
        header('Location: ' . $paymenter->authorizationUrl(), true, 302);
        exit;
    }

    private function paymenterCallback(Request $request): never
    {
        $state = trim((string) ($_COOKIE['foxnetwork_oauth_state'] ?? ''));
        $code = trim((string) $request->query('code', ''));
        $oauthError = trim((string) $request->query('error', ''));

        setcookie('foxnetwork_oauth_state', '', [
            'expires' => time() - 3600,
            'path' => '/api/paymenter',
            'httponly' => true,
            'samesite' => 'Lax',
        ]);

        if ($state === '') {
            Response::html($this->oauthPage(
                false,
                'The secure login cookie is missing. Start login again from the FoxNetwork app.'
            ), 422);
        }

        $statement = $this->db->prepare(
            'SELECT * FROM oauth_states
             WHERE state_hash = :state_hash AND expires_at > :now
             LIMIT 1'
        );
        $statement->execute([
            'state_hash' => hash('sha256', $state),
            'now' => (new DateTimeImmutable())->format(DATE_ATOM),
        ]);
        $oauthState = $statement->fetch();

        if (!$oauthState) {
            Response::html($this->oauthPage(false, 'This login request expired. Please try again.'), 422);
        }

        if ($oauthError !== '') {
            $this->markOAuthFailed((int) $oauthState['id'], $oauthError);
            Response::html($this->oauthPage(false, 'Paymenter login was cancelled.'), 400);
        }

        if ($code === '') {
            $this->markOAuthFailed((int) $oauthState['id'], 'Missing authorization code');
            Response::html($this->oauthPage(false, 'No authorization code was returned.'), 422);
        }

        try {
            $paymenter = new PaymenterOAuthClient($this->config);
            $tokenData = $paymenter->exchangeCode($code);
            $paymenterToken = (string) ($tokenData['access_token'] ?? '');

            if ($paymenterToken === '') {
                throw new \RuntimeException('Paymenter did not return an access token.');
            }

            $remote = $paymenter->currentUser($paymenterToken);
            $remote = isset($remote['data']) && is_array($remote['data'])
                ? $remote['data']
                : $remote;

            $user = $this->findOrCreatePaymenterUser($remote);
            $localToken = $this->auth->createToken((int) $user['id']);
            $publicUser = $this->publicUser($user);

            $update = $this->db->prepare(
                'UPDATE oauth_states
                 SET status = :status,
                     result_token = :result_token,
                     result_user_json = :result_user_json,
                     error_message = NULL
                 WHERE id = :id'
            );
            $update->execute([
                'status' => 'complete',
                'result_token' => $localToken['plain'],
                'result_user_json' => json_encode($publicUser),
                'id' => (int) $oauthState['id'],
            ]);

            Response::html($this->oauthPage(true, 'You are signed in. Return to the FoxNetwork app.'));
        } catch (\Throwable $exception) {
            $this->markOAuthFailed((int) $oauthState['id'], $exception->getMessage());
            Response::html($this->oauthPage(false, 'Login failed: ' . $exception->getMessage()), 500);
        }
    }

    private function paymenterStatus(Request $request): never
    {
        $state = trim((string) $request->query('state', ''));

        if ($state === '') {
            Response::json(['message' => 'State is required'], 422);
        }

        $statement = $this->db->prepare(
            'SELECT * FROM oauth_states WHERE state_hash = :state_hash LIMIT 1'
        );
        $statement->execute(['state_hash' => hash('sha256', $state)]);
        $oauthState = $statement->fetch();

        if (!$oauthState) {
            Response::json(['status' => 'expired'], 404);
        }

        if ($oauthState['status'] === 'complete') {
            $user = json_decode((string) $oauthState['result_user_json'], true);

            $delete = $this->db->prepare('DELETE FROM oauth_states WHERE id = :id');
            $delete->execute(['id' => (int) $oauthState['id']]);

            Response::json([
                'status' => 'complete',
                'token' => (string) $oauthState['result_token'],
                'user' => is_array($user) ? $user : [],
            ]);
        }

        if ($oauthState['status'] === 'failed') {
            $message = (string) ($oauthState['error_message'] ?? 'Paymenter login failed');

            $delete = $this->db->prepare('DELETE FROM oauth_states WHERE id = :id');
            $delete->execute(['id' => (int) $oauthState['id']]);

            Response::json([
                'status' => 'failed',
                'message' => $message,
            ]);
        }

        Response::json(['status' => 'pending']);
    }

    private function findOrCreatePaymenterUser(array $remote): array
    {
        $paymenterId = (int) ($remote['id'] ?? 0);
        $email = strtolower(trim((string) ($remote['email'] ?? '')));
        $name = trim((string) (
            $remote['name']
            ?? trim(((string) ($remote['first_name'] ?? '')) . ' ' . ((string) ($remote['last_name'] ?? '')))
        ));

        if ($paymenterId <= 0 || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new \RuntimeException('Paymenter returned an incomplete user profile.');
        }

        if ($name === '') {
            $name = $email;
        }

        $find = $this->db->prepare(
            'SELECT * FROM users
             WHERE paymenter_id = :paymenter_id OR lower(email) = :email
             LIMIT 1'
        );
        $find->execute([
            'paymenter_id' => $paymenterId,
            'email' => $email,
        ]);
        $user = $find->fetch();

        if ($user) {
            $update = $this->db->prepare(
                'UPDATE users
                 SET name = :name, email = :email, paymenter_id = :paymenter_id
                 WHERE id = :id'
            );
            $update->execute([
                'name' => $name,
                'email' => $email,
                'paymenter_id' => $paymenterId,
                'id' => (int) $user['id'],
            ]);

            $user['name'] = $name;
            $user['email'] = $email;
            $user['paymenter_id'] = $paymenterId;
            return $user;
        }

        $insert = $this->db->prepare(
            'INSERT INTO users (name, email, password_hash, paymenter_id, created_at)
             VALUES (:name, :email, :password_hash, :paymenter_id, :created_at)'
        );
        $insert->execute([
            'name' => $name,
            'email' => $email,
            'password_hash' => password_hash(bin2hex(random_bytes(32)), PASSWORD_DEFAULT),
            'paymenter_id' => $paymenterId,
            'created_at' => (new DateTimeImmutable())->format(DATE_ATOM),
        ]);

        return [
            'id' => (int) $this->db->lastInsertId(),
            'name' => $name,
            'email' => $email,
            'paymenter_id' => $paymenterId,
        ];
    }

    private function markOAuthFailed(int $id, string $message): void
    {
        $statement = $this->db->prepare(
            'UPDATE oauth_states
             SET status = :status, error_message = :message
             WHERE id = :id'
        );
        $statement->execute([
            'status' => 'failed',
            'message' => substr($message, 0, 500),
            'id' => $id,
        ]);
    }

    private function oauthPage(bool $success, string $message): string
    {
        $title = $success ? 'Login successful' : 'Login failed';
        $icon = $success ? '✓' : '!';
        $safeTitle = htmlspecialchars($title, ENT_QUOTES, 'UTF-8');
        $safeMessage = htmlspecialchars($message, ENT_QUOTES, 'UTF-8');

        return <<<HTML
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{$safeTitle}</title>
<style>
body{margin:0;min-height:100vh;display:grid;place-items:center;background:#07111f;color:#f7fbff;font-family:system-ui,sans-serif}
main{width:min(420px,calc(100% - 40px));padding:32px;border:1px solid #22364d;border-radius:20px;background:#0d1b2b;text-align:center}
.icon{width:64px;height:64px;display:grid;place-items:center;margin:0 auto 18px;border-radius:50%;background:#18344c;color:#25d8ff;font-size:36px;font-weight:800}
h1{margin:0 0 12px}p{margin:0;color:#b9c9d8;line-height:1.5}
</style>
</head>
<body><main><div class="icon">{$icon}</div><h1>{$safeTitle}</h1><p>{$safeMessage}</p></main></body>
</html>
HTML;
    }

    private function login(Request $request): never
    {
        $email = strtolower(trim((string) $request->input('email', '')));
        $password = (string) $request->input('password', '');

        if (!filter_var($email, FILTER_VALIDATE_EMAIL) || $password === '') {
            Response::json(['message' => 'Email and password are required'], 422);
        }

        $statement = $this->db->prepare('SELECT * FROM users WHERE lower(email) = :email LIMIT 1');
        $statement->execute(['email' => $email]);
        $user = $statement->fetch();

        if (!$user || empty($user['password_hash']) || !password_verify($password, (string) $user['password_hash'])) {
            Response::json(['message' => 'Invalid email or password'], 401);
        }

        $token = $this->auth->createToken((int) $user['id']);

        Response::json([
            'token' => $token['plain'],
            'expires_at' => $token['expires_at'],
            'user' => $this->publicUser($user),
        ]);
    }

    /** @param array<string,mixed> $user */
    private function services(array $user): never
    {
        try {
            $client = new PaymenterAdminClient($this->config);
            $rows = $client->servicesForUser((int) ($user['paymenter_id'] ?? 0));
            Response::json($rows, 200, [
                'Cache-Control' => 'no-store, no-cache, must-revalidate, max-age=0',
                'X-FoxNetwork-Services-Source' => 'paymenter',
            ]);
        } catch (\Throwable $e) {
            $detail = $e->getMessage();
            $authError = str_contains($detail, 'HTTP 401') || str_contains($detail, 'HTTP 403')
                || str_contains(strtolower($detail), 'token is missing');
            Response::json([
                'message' => $detail !== ''
                    ? $detail
                    : ($authError
                        ? 'Paymenter API credentials were rejected. Check the admin API token.'
                        : 'Paymenter is temporarily unavailable. Please try again.'),
                'error' => $detail,
                'source' => 'paymenter',
                'retryable' => !$authError,
            ], $authError ? 502 : 503, [
                'Cache-Control' => 'no-store',
                'Retry-After' => $authError ? '0' : '5',
                'X-FoxNetwork-Services-Source' => 'paymenter-error',
            ]);
        }
    }

    private function power(Request $request, int $userId, int $serviceId): never
    {
        $action = strtolower(trim((string) $request->input('action', '')));

        if (!in_array($action, ['start', 'stop', 'restart'], true)) {
            Response::json(['message' => 'Action must be start, stop, or restart'], 422);
        }

        $statement = $this->db->prepare(
            'SELECT * FROM services WHERE id = :id AND user_id = :user_id LIMIT 1'
        );
        $statement->execute(['id' => $serviceId, 'user_id' => $userId]);
        $service = $statement->fetch();

        if (!$service) {
            Response::json(['message' => 'Service not found'], 404);
        }

        $client = new PterodactylClient($this->config);
        $client->sendPowerAction($service, $action);

        $newStatus = $action === 'stop' ? 'Offline' : 'Online';
        $update = $this->db->prepare('UPDATE services SET status = :status WHERE id = :id');
        $update->execute(['status' => $newStatus, 'id' => $serviceId]);

        $log = $this->db->prepare(
            'INSERT INTO power_actions (service_id, action, created_at)
             VALUES (:service_id, :action, :created_at)'
        );
        $log->execute([
            'service_id' => $serviceId,
            'action' => $action,
            'created_at' => (new DateTimeImmutable())->format(DATE_ATOM),
        ]);

        Response::json([
            'message' => ucfirst($action) . ' command sent',
            'status' => $newStatus,
        ]);
    }

    /** @param array<string,mixed> $user */
    private function invoices(array $user): never
    {
        try {
            $client = new PaymenterAdminClient($this->config);
            $rows = $client->invoicesForUser((int) ($user['paymenter_id'] ?? 0));
            Response::json($rows, 200, [
                'Cache-Control' => 'no-store, no-cache, must-revalidate, max-age=0',
                'X-FoxNetwork-Billing-Source' => 'paymenter',
            ]);
        } catch (\Throwable $e) {
            Response::json([
                'message' => 'Could not load invoices from Paymenter.',
                'error' => $e->getMessage(),
                'source' => 'paymenter',
            ], 503, [
                'Cache-Control' => 'no-store',
                'Retry-After' => '5',
            ]);
        }
    }

    /** @param array<string,mixed> $user */
    private function tickets(array $user): never
    {
        $local = $this->localTickets((int) $user['id']);

        try {
            $client = new PaymenterAdminClient($this->config);
            $remote = $client->ticketsForUser((int) ($user['paymenter_id'] ?? 0));
            Response::json(array_values(array_merge($local, $remote)), 200, [
                'Cache-Control' => 'no-store, no-cache, must-revalidate, max-age=0',
                'X-FoxNetwork-Support-Source' => 'paymenter+local',
            ]);
        } catch (\Throwable $e) {
            // Locally created mobile tickets remain available when Paymenter is temporarily down.
            Response::json($local, 200, [
                'Cache-Control' => 'no-store',
                'X-FoxNetwork-Support-Source' => 'local-fallback',
                'X-FoxNetwork-Support-Warning' => mb_substr($e->getMessage(), 0, 200),
            ]);
        }
    }

    /** @return array<int,array<string,mixed>> */
    private function localTickets(int $userId): array
    {
        $statement = $this->db->prepare(
            'SELECT id, subject, status, updated_at
             FROM tickets WHERE user_id = :user_id ORDER BY updated_at DESC'
        );
        $statement->execute(['user_id' => $userId]);
        $rows = $statement->fetchAll();

        return array_map(static fn(array $row): array => [
            'id' => (int) $row['id'],
            'subject' => (string) $row['subject'],
            'status' => (string) $row['status'],
            'updated_at' => (string) $row['updated_at'],
            'updatedAt' => (string) $row['updated_at'],
            'source' => 'mobile',
        ], $rows);
    }

    private function createTicket(Request $request, int $userId): never
    {
        $subject = trim((string) $request->input('subject', ''));
        $message = trim((string) $request->input('message', ''));

        if ($subject === '' || $message === '') {
            Response::json(['message' => 'Subject and message are required'], 422);
        }
        if (mb_strlen($subject) > 190) {
            Response::json(['message' => 'The subject may not exceed 190 characters'], 422);
        }
        if (mb_strlen($message) > 10000) {
            Response::json(['message' => 'The message may not exceed 10000 characters'], 422);
        }

        $now = (new DateTimeImmutable())->format(DATE_ATOM);
        $statement = $this->db->prepare(
            'INSERT INTO tickets (user_id, subject, message, status, updated_at, created_at)
             VALUES (:user_id, :subject, :message, :status, :updated_at, :created_at)'
        );
        $statement->execute([
            'user_id' => $userId,
            'subject' => $subject,
            'message' => $message,
            'status' => 'Open',
            'updated_at' => $now,
            'created_at' => $now,
        ]);

        Response::json([
            'id' => (int) $this->db->lastInsertId(),
            'subject' => $subject,
            'status' => 'Open',
            'updated_at' => $now,
            'updatedAt' => $now,
            'source' => 'mobile',
            'message' => 'Support ticket created',
        ], 201);
    }

    /** @param array<string, mixed> $user */
    private function publicUser(array $user): array
    {
        return [
            'id' => (int) $user['id'],
            'name' => $user['name'],
            'email' => $user['email'],
        ];
    }
}
