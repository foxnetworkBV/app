# FoxNetwork Customer App

Flutter customer app for FoxNetwork.

## Works on Windows

You can open and develop this project in:

- Visual Studio Code
- Android Studio

You can test it on:

- Android
- Windows
- Chrome

The same project can later be compiled for iPhone using a Mac with Xcode.

## Included

- Login screen
- Demo login
- Dashboard
- Hosting services
- Start, stop and restart controls
- Billing and invoices
- Support tickets
- Customer account
- FoxNetwork dark theme
- API client
- Secure-enough local token storage for development
- Demo mode

## Install Flutter on Windows

1. Download Flutter SDK.
2. Extract it to `C:\src\flutter`.
3. Add `C:\src\flutter\bin` to PATH.
4. Install Visual Studio Code.
5. Install the Flutter and Dart extensions.
6. Open a terminal and run:

```powershell
flutter doctor
```

## Open this project

```powershell
cd FoxNetworkFlutterApp
flutter pub get
flutter run -d chrome
```

For Android:

```powershell
flutter run
```

## API configuration

Open:

```text
lib/config/api_config.dart
```

Change:

```dart
static const String baseUrl = 'https://api.foxnetwork.be';
```

Set demo mode to false when your API is ready:

```dart
static const bool demoMode = false;
```

## Expected API endpoints

- POST `/api/login`
- GET `/api/me`
- GET `/api/services`
- POST `/api/services/{id}/power`
- GET `/api/invoices`
- GET `/api/tickets`
- POST `/api/tickets`
- POST `/api/logout`

Login response:

```json
{
  "token": "api-token",
  "user": {
    "id": 1,
    "name": "Louis Beke",
    "email": "louis@foxnetwork.be"
  }
}
```


## Real Paymenter login

The app now uses Paymenter OAuth. Set the backend URL in:

```text
lib/config/api_config.dart
```

### Generate native Flutter folders

This ZIP contains the application source. Inside the project folder run:

```powershell
flutter create .
flutter pub get
```

### Android callback

After `flutter create .`, open:

```text
android/app/src/main/AndroidManifest.xml
```

Inside the main `<activity>` add:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="foxnetwork"
        android:host="oauth"
        android:path="/callback" />
</intent-filter>
```

### iOS callback

On a Mac, after generating the iOS folder, add this inside the main `<dict>` in:

```text
ios/Runner/Info.plist
```

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>foxnetwork</string>
        </array>
    </dict>
</array>
```

The Paymenter OAuth redirect must be exactly:

```text
foxnetwork://oauth/callback
```
