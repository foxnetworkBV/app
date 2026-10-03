# FoxNetwork customer app

Native Flutter customer app for the Paymenter installation at
https://client.foxnetwork.be. Build from **this repository root**; the nested
`foxnetwork_app/` directory is an older copy and is not used by the root release
workflow.

## Paymenter setup required

Install the integration in [paymenter-mobile](paymenter-mobile/README.md) on the
Paymenter server before using the app. It provides customer-scoped services,
invoices, support tickets, logout, and optional Pterodactyl controls.

The app signs in through Paymenter's system-browser OAuth flow with PKCE and a
public client. Paymenter handles passwords and 2FA; access and refresh tokens use
platform secure storage. The retired API server and `mobile-*.php` endpoints are
not used by the root app.

The callback registered in Passport must be exactly:

```text
foxnetwork://oauth/callback
```

Configure the public client ID on the Paymenter server, as described in the
installation guide. The app reads it from `/api/foxnetwork/config`. No client
secret or admin API token belongs in the app.

## Develop and test

```sh
flutter pub get
flutter analyze lib test
flutter test
flutter run
```

Native authentication targets Android (API 24+) and iOS (15+). Web and Windows
builds offer a browser portal link; their native OAuth flows are not implemented.
Building iOS requires macOS and Xcode. Android and iOS callback configuration and
iOS Keychain entitlements are included.

Services, invoices, ticket lists/details and ticket creation stay native.
Payments and ticket replies open the authenticated Paymenter website. Server
resource usage, console and power controls become available for active services
when the optional Pterodactyl configuration is installed.

Local tests use mocked HTTP and authentication plugins. Complete the server
feature tests and real-device login checks in the installation guide before a
release. The repository does not include access to the live Paymenter server.
