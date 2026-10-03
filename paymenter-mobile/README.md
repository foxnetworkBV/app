# Paymenter integration for the FoxNetwork app

Install these files **inside the Paymenter installation serving
https://client.foxnetwork.be**. They add `/api/foxnetwork/*` routes to that
installation. No separate API server or Paymenter admin API token is required.

The Flutter app uses Passport authorization-code login with PKCE through the
system browser. Paymenter handles passwords, CAPTCHA and 2FA. The app requests
`profile` and `foxnetwork:customer` scopes and stores its tokens in platform
secure storage. Each customer query starts from the authenticated user's
relationships; the API never accepts a customer ID from the app.

## Install on the Paymenter server

These files target Paymenter 1.x's models and Laravel Passport public clients.
Check compatibility and run the included feature tests on a staging copy before
deploying. This repository does not contain the Paymenter application or its
database. Copy the files below into the corresponding directories in Paymenter:

```text
app/Http/Controllers/FoxNetworkMobileController.php
app/Http/Middleware/FoxNetworkMobileAccess.php
app/Providers/FoxNetworkMobileServiceProvider.php
config/foxnetwork.php
routes/foxnetwork-mobile.php
```

Add this entry to the existing array in `bootstrap/providers.php`:

```php
App\Providers\FoxNetworkMobileServiceProvider::class,
```

From the Paymenter directory, create a **public authorization-code client**:

```sh
php artisan passport:client --public
```

Use `FoxNetwork Mobile` for the name and exactly
`foxnetwork://oauth/callback` for the redirect URI. On Passport 13 the equivalent
non-interactive command is:

```sh
php artisan passport:client --public --name="FoxNetwork Mobile" --redirect_uri="foxnetwork://oauth/callback"
```

Put the resulting **client ID** in Paymenter's `.env`:

```dotenv
FOXNETWORK_MOBILE_CLIENT_ID=the-public-client-id
```

Use a public client without a secret. The app obtains the public ID from the
configuration endpoint; no ID needs embedding in the Flutter build. Do not use
the admin API key or a confidential OAuth client for this.

Then run:

```sh
php artisan optimize:clear
php artisan route:list --path=foxnetwork
php artisan route:list --path=oauth
```

Paymenter's `/oauth/authorize` and `/api/oauth/token` must work. The site returned
HTTP 500 on its OAuth routes during development. Check `storage/logs/laravel.log`
if this persists. Verify the Passport keys exist and are readable by PHP; only
generate them with `php artisan passport:keys` if they are missing. Do not replace
existing keys, which would invalidate other integrations. The normal Passport
authorization approval and denial routes must also be registered.

Verify `APP_URL=https://client.foxnetwork.be`, HTTPS, and forwarded proxy headers.
Only rebuild your normal configuration/route caches after these checks pass.

## Webhosting and other service categories

Create your product categories in Paymenter (for example `WEB`, `VPS`, `Game`,
or `Email`) and assign products to them. Customers' services automatically
appear in the app under the product's category. The app builds its filters from
these names, so new categories do not require an app update. Products without
a category appear under `Other`.

The `Order a new service` button opens the Paymenter storefront. After checkout,
returning to the app refreshes the service list. Product creation and customer
ordering remain managed by Paymenter.

Webhosting and other services show their status, price, renewal date, and a
customer portal management button. Native console and power controls are only
enabled for active products using the `Pterodactyl` server extension with an
explicit mapping. Webhosting control-panel actions remain in Paymenter.

## Optional Pterodactyl controls

Service, invoice and ticket screens work without panel credentials. To enable
native resource usage, console and power controls for specific services, set:

```dotenv
FOXNETWORK_PANEL_URL=https://panel.foxnetwork.be
FOXNETWORK_PANEL_CLIENT_KEY=your-server-side-pterodactyl-client-api-key
FOXNETWORK_SERVER_MAP='{"123":"a1b2c3d4"}'
```

The mapping key is the **Paymenter service ID** and its value is the
**Pterodactyl server identifier**. Verify every mapping against the customer's
actual service before enabling it. The client key needs access to those servers;
an application API key cannot call Pterodactyl's client resources/power/websocket
endpoints. Keep it in Paymenter's `.env` only. Clear the configuration cache
after changes. Suspended services and unmapped services show a portal button
without native controls. Invoice payments and ticket replies open Paymenter's
authenticated website; creating and reading tickets remain native.

## Verify before release

1. `GET /api/foxnetwork/config` returns a public `client_id`.
2. `GET /api/foxnetwork/me` without authentication returns 401.
3. Complete app login, including 2FA if enabled, and approve the mobile scopes.
4. Check services, invoice totals and details, ticket messages, and ticket creation.
5. Verify a second customer's invoice/ticket/service IDs return 404.
6. Check expiry/refresh and sign-out; revoked tokens must return 401.
7. If configured, test panel controls on a disposable server.

Copy `tests/Feature/FoxNetworkMobileTest.php` into Paymenter's tests directory and
run `php artisan test --filter=FoxNetworkMobileTest` against a **dedicated test
database**. These tests use `RefreshDatabase`, which resets that database.

Locally, the Flutter tests and PHP syntax checks can run without a deployed
Paymenter instance. Full server tests and mobile browser callback tests require
the installed integration and an Android/iOS device. Authentication in this
Flutter project targets Android and iOS; the web/Windows builds display a portal
link and do not implement native OAuth sign-in.

## References

- [Paymenter OAuth](https://paymenter.org/development/OAuth)
- [Passport PKCE](https://laravel.com/docs/12.x/passport#authorization-code-grant-with-pkce)
- [Flutter AppAuth platform setup](https://pub.dev/packages/flutter_appauth)
