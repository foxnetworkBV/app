<?php

declare(strict_types=1);

namespace FoxNetwork\Integrations;

use FoxNetwork\Config;
use RuntimeException;

final class PaymenterAdminClient
{
    private string $baseUrl;
    private string $token;

    public function __construct(private Config $config)
    {
        $this->baseUrl = rtrim((string) $config->get('PAYMENTER_URL', ''), '/');
        $this->token = trim((string) $config->get('PAYMENTER_ADMIN_API_TOKEN', ''));

        if (str_starts_with(strtolower($this->token), 'bearer ')) {
            $this->token = trim(substr($this->token, 7));
        }

        if ($this->baseUrl === '') {
            throw new RuntimeException('PAYMENTER_URL is missing.');
        }

        if ($this->token === '') {
            throw new RuntimeException('Paymenter admin API token is missing.');
        }
    }

    /**
     * Return only the Paymenter services owned by the authenticated Paymenter user.
     *
     * @return array<int, array<string, mixed>>
     */
    public function servicesForUser(int $paymenterUserId): array
    {
        if ($paymenterUserId <= 0) {
            throw new RuntimeException('The local user is not linked to a Paymenter user.');
        }

        $payload = $this->request(
            '/api/v1/admin/services?include=user,order,product&per_page=100'
        );

        $services = isset($payload['data']) && is_array($payload['data'])
            ? $payload['data']
            : [];

        $included = isset($payload['included']) && is_array($payload['included'])
            ? $payload['included']
            : [];

        $includedIndex = $this->buildIncludedIndex($included);
        $matched = [];

        foreach ($services as $service) {
            if (!is_array($service)) {
                continue;
            }

            // Paymenter JSON:API stores ownership here:
            // relationships.user.data.id
            $ownerId = (int) (
                $service['relationships']['user']['data']['id']
                ?? $service['attributes']['user_id']
                ?? $service['user_id']
                ?? 0
            );

            if ($ownerId !== $paymenterUserId) {
                continue;
            }

            $matched[] = $this->normaliseService($service, $includedIndex);
        }

        return $matched;
    }


    /** @return array<int, array<string, mixed>> */
    public function invoicesForUser(int $paymenterUserId): array
    {
        if ($paymenterUserId <= 0) {
            throw new RuntimeException('The local user is not linked to a Paymenter user.');
        }

        $payload = $this->request('/api/v1/admin/invoices?include=user&per_page=100&sort=-id');
        $items = isset($payload['data']) && is_array($payload['data']) ? $payload['data'] : [];
        $result = [];

        foreach ($items as $item) {
            if (!is_array($item)) continue;
            $ownerId = $this->ownerId($item);
            if ($ownerId !== $paymenterUserId) continue;

            $a = isset($item['attributes']) && is_array($item['attributes']) ? $item['attributes'] : [];
            $id = (int) ($a['id'] ?? $item['id'] ?? 0);
            $total = $a['total'] ?? $a['amount'] ?? $a['price'] ?? 0;
            $number = $a['number'] ?? $a['invoice_number'] ?? ('INV-' . $id);
            $currency = $a['currency_code'] ?? $a['currency'] ?? 'EUR';
            $status = (string) ($a['status'] ?? 'unknown');
            $due = $a['due_date'] ?? $a['due_at'] ?? '';

            $result[] = [
                'id' => $id,
                'number' => (string) $number,
                'amount' => is_numeric($total) ? (float) $total : 0.0,
                'currency' => (string) $currency,
                'currency_code' => (string) $currency,
                'status' => ucfirst(strtolower($status)),
                'due_date' => (string) $due,
                'dueDate' => (string) $due,
                'created_at' => $a['created_at'] ?? null,
                'source' => 'paymenter',
            ];
        }

        return $result;
    }

    /** @return array<int, array<string, mixed>> */
    public function ticketsForUser(int $paymenterUserId): array
    {
        if ($paymenterUserId <= 0) {
            throw new RuntimeException('The local user is not linked to a Paymenter user.');
        }

        $payload = $this->request('/api/v1/admin/tickets?include=user&per_page=100&sort=-updated_at');
        $items = isset($payload['data']) && is_array($payload['data']) ? $payload['data'] : [];
        $result = [];

        foreach ($items as $item) {
            if (!is_array($item)) continue;
            if ($this->ownerId($item) !== $paymenterUserId) continue;
            $a = isset($item['attributes']) && is_array($item['attributes']) ? $item['attributes'] : [];
            $id = (int) ($a['id'] ?? $item['id'] ?? 0);
            $result[] = [
                'id' => $id,
                'subject' => (string) ($a['subject'] ?? ('Ticket #' . $id)),
                'status' => ucfirst(strtolower((string) ($a['status'] ?? 'open'))),
                'updated_at' => (string) ($a['updated_at'] ?? $a['created_at'] ?? ''),
                'updatedAt' => (string) ($a['updated_at'] ?? $a['created_at'] ?? ''),
                'source' => 'paymenter',
            ];
        }

        return $result;
    }

    /** @param array<string,mixed> $resource */
    private function ownerId(array $resource): int
    {
        return (int) (
            $resource['relationships']['user']['data']['id']
            ?? $resource['attributes']['user_id']
            ?? $resource['user_id']
            ?? 0
        );
    }

    /**
     * Diagnostic information for the protected debug endpoint.
     *
     * @return array<string, mixed>
     */
    public function diagnostics(int $paymenterUserId): array
    {
        $payload = $this->request(
            '/api/v1/admin/services?include=user,order,product&per_page=100'
        );

        $services = isset($payload['data']) && is_array($payload['data'])
            ? $payload['data']
            : [];

        $included = isset($payload['included']) && is_array($payload['included'])
            ? $payload['included']
            : [];

        $includedIndex = $this->buildIncludedIndex($included);
        $ownerIds = [];
        $matched = [];

        foreach ($services as $service) {
            if (!is_array($service)) {
                continue;
            }

            $ownerId = (int) (
                $service['relationships']['user']['data']['id']
                ?? $service['attributes']['user_id']
                ?? $service['user_id']
                ?? 0
            );

            if ($ownerId > 0) {
                $ownerIds[] = $ownerId;
            }

            if ($ownerId === $paymenterUserId) {
                $matched[] = $this->normaliseService($service, $includedIndex);
            }
        }

        return [
            'paymenter_user_id' => $paymenterUserId,
            'received_service_count' => count($services),
            'matched_service_count' => count($matched),
            'detected_owner_ids' => array_values(array_unique($ownerIds)),
            'matched_services' => $matched,
        ];
    }

    /**
     * @param array<string, mixed> $service
     * @param array<string, array<string, mixed>> $includedIndex
     * @return array<string, mixed>
     */
    private function normaliseService(array $service, array $includedIndex): array
    {
        $attributes = isset($service['attributes']) && is_array($service['attributes'])
            ? $service['attributes']
            : [];

        $serviceId = (int) ($attributes['id'] ?? $service['id'] ?? 0);

        $productId = (string) (
            $service['relationships']['product']['data']['id']
            ?? ''
        );

        $orderId = (string) (
            $service['relationships']['order']['data']['id']
            ?? ''
        );

        $product = $productId !== ''
            ? ($includedIndex['products:' . $productId]['attributes'] ?? [])
            : [];

        $order = $orderId !== ''
            ? ($includedIndex['orders:' . $orderId]['attributes'] ?? [])
            : [];

        if (!is_array($product)) {
            $product = [];
        }

        if (!is_array($order)) {
            $order = [];
        }

        $name = trim((string) (
            $product['name']
            ?? $attributes['name']
            ?? ('Service #' . $serviceId)
        ));

        $status = strtolower(trim((string) ($attributes['status'] ?? 'unknown')));
        $displayStatus = match ($status) {
            'active' => 'Active',
            'pending' => 'Pending',
            'suspended' => 'Suspended',
            'cancelled', 'canceled' => 'Cancelled',
            'terminated' => 'Terminated',
            default => ucfirst($status),
        };

        $price = is_numeric($attributes['price'] ?? null)
            ? (float) $attributes['price']
            : 0.0;

        $currency = (string) (
            $attributes['currency_code']
            ?? $order['currency_code']
            ?? 'EUR'
        );

        $expiresAt = $attributes['expires_at'] ?? null;

        return [
            'id' => $serviceId,
            'service_id' => $serviceId,
            'name' => $name,
            'product_name' => $name,
            'product_id' => $productId !== '' ? (int) $productId : null,
            'order_id' => $orderId !== '' ? (int) $orderId : null,
            'quantity' => (int) ($attributes['quantity'] ?? 1),
            'price' => $price,
            'currency' => $currency,
            'currency_code' => $currency,
            'status' => $displayStatus,
            'status_raw' => $status,
            'expires_at' => $expiresAt,
            'expiresAt' => $expiresAt,
            'description' => (string) ($product['description'] ?? ''),
            'slug' => (string) ($product['slug'] ?? ''),
            'image' => $product['image'] ?? null,
            'created_at' => $attributes['created_at'] ?? null,
            'updated_at' => $attributes['updated_at'] ?? null,
            'source' => 'paymenter',
        ];
    }

    /**
     * @param array<int, mixed> $included
     * @return array<string, array<string, mixed>>
     */
    private function buildIncludedIndex(array $included): array
    {
        $index = [];

        foreach ($included as $item) {
            if (!is_array($item)) {
                continue;
            }

            $type = (string) ($item['type'] ?? '');
            $id = (string) ($item['id'] ?? '');

            if ($type === '' || $id === '') {
                continue;
            }

            $index[$type . ':' . $id] = $item;
        }

        return $index;
    }

    /**
     * @return array<string, mixed>
     */
    private function request(string $path): array
    {
        $url = $this->baseUrl . '/' . ltrim($path, '/');
        $lastError = 'Unknown Paymenter request error.';

        for ($attempt = 1; $attempt <= 3; $attempt++) {
            $curl = curl_init($url);

            if ($curl === false) {
                throw new RuntimeException('Unable to initialise cURL.');
            }

            curl_setopt_array($curl, [
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_FOLLOWLOCATION => true,
                CURLOPT_MAXREDIRS => 5,
                CURLOPT_CONNECTTIMEOUT => 10,
                CURLOPT_TIMEOUT => 30,
                CURLOPT_HTTPHEADER => [
                    'Authorization: Bearer ' . $this->token,
                    'Accept: application/json',
                    'User-Agent: FoxNetwork-API/4.3',
                    'Connection: close',
                ],
                CURLOPT_ENCODING => '',
                CURLOPT_IPRESOLVE => CURL_IPRESOLVE_V4,
            ]);

            $body = curl_exec($curl);
            $status = (int) curl_getinfo($curl, CURLINFO_HTTP_CODE);
            $curlError = curl_error($curl);
            $curlNumber = curl_errno($curl);
            curl_close($curl);

            if ($body === false || $curlNumber !== 0) {
                $lastError = sprintf(
                    'Paymenter connection failed (cURL %d): %s',
                    $curlNumber,
                    $curlError !== '' ? $curlError : 'Unknown cURL error'
                );

                if ($attempt < 3) {
                    usleep(300000 * $attempt);
                    continue;
                }

                throw new RuntimeException($lastError);
            }

            if ($status === 401 || $status === 403) {
                throw new RuntimeException(
                    'Paymenter returned HTTP ' . $status . ': the admin API token was rejected.'
                );
            }

            if ($status === 404) {
                throw new RuntimeException(
                    'Paymenter returned HTTP 404 for ' . $url . '. Check PAYMENTER_URL and the API route.'
                );
            }

            if ($status >= 500 && $attempt < 3) {
                $lastError = 'Paymenter returned HTTP ' . $status . '.';
                usleep(300000 * $attempt);
                continue;
            }

            if ($status < 200 || $status >= 300) {
                $preview = trim(strip_tags((string) $body));
                $preview = mb_substr($preview, 0, 300);

                throw new RuntimeException(
                    'Paymenter returned HTTP ' . $status
                    . ($preview !== '' ? ': ' . $preview : '.')
                );
            }

            $decoded = json_decode((string) $body, true);

            if (!is_array($decoded)) {
                throw new RuntimeException(
                    'Paymenter returned invalid JSON: ' . json_last_error_msg()
                );
            }

            return $decoded;
        }

        throw new RuntimeException($lastError);
    }
}
