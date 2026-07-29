# FoxNetwork 1.1.0 (Build 21)

This release keeps the existing API integration and adds a production-style UI refresh.

## Included
- Human-readable local dates and relative dates
- Consistent currency formatting
- Search and status filters for invoices
- Improved invoice cards and detail status badges
- Redesigned dashboard with refresh and active-service summary
- Expanded Account page with working external, email, support, legal and portal links
- Copy-on-long-press for the account email
- Better loading, empty and error states
- Material 3 presentation retained

## Build
Run from the folder containing `pubspec.yaml`:

```bash
flutter clean
rm -rf ios/Flutter/ephemeral ios/Pods ios/Podfile.lock .dart_tool build
flutter pub get
cd ios && pod install --repo-update && cd ..
open ios/Runner.xcworkspace
```

Confirm Xcode shows version `1.1.0` and build `21` before archiving.
