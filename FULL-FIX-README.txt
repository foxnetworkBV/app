FOXNETWORK iOS FULL FIX

This package fixes:
- iOS deployment target 13 -> 15
- duplicate/new implicit Flutter engine lifecycle
- UIScene startup path removed
- Impeller disabled for iOS 27 beta compatibility
- missing Podfile added
- clean CocoaPods/Xcode build
- TestFlight build version changed to 1.0.5 (7)

CODEMAGIC:
1. Upload/commit this complete project.
2. In Codemagic, select the ios-testflight workflow from codemagic.yaml.
3. Ensure the App Store Connect integration name is exactly:
   FoxNetwork App Store Connect
   If yours has another name, replace that line in codemagic.yaml.
4. Start a new build.
5. Do not reuse build 6 or an old cached IPA.
6. Install build 7 from TestFlight.

IMPORTANT:
The supplied crash report is from iOS 27.0 beta. The crash occurs inside Flutter.framework before Dart starts. The compatibility changes above avoid the most likely Flutter engine startup paths. If build 7 still crashes only on iOS 27 beta, test it on stable iOS. That remaining issue would be an iOS beta / Flutter engine incompatibility, not your Dart app.
