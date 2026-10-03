<?php

return [
    // The ID of a Passport PUBLIC authorization-code client (PKCE).
    'client_id' => env('FOXNETWORK_MOBILE_CLIENT_ID', ''),
    // Optional server controls. Keep this client API key on the server only.
    'panel_url' => env('FOXNETWORK_PANEL_URL', 'https://panel.foxnetwork.be'),
    'panel_client_key' => env('FOXNETWORK_PANEL_CLIENT_KEY', ''),
    // Explicit Paymenter service ID => Pterodactyl server identifier mapping.
    'server_map' => json_decode(env('FOXNETWORK_SERVER_MAP', '{}'), true) ?: [],
];
