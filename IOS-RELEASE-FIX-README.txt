FoxNetwork iOS Release Fix – 1.0.6 (11)
=========================================

Applied fixes
-------------
- Codemagic builds a signed release IPA only.
- Added flutter analyze and flutter test before archiving.
- Bundle identifier verified as be.foxnetwork.app.
- iOS minimum version remains 15.0.
- Added the foxnetwork:// OAuth callback URL scheme.
- Added ITSAppUsesNonExemptEncryption=false for App Store Connect.
- Impeller remains disabled as a compatibility workaround.
- App display name normalized to FoxNetwork.
- Version increased to 1.0.6+11.

Build from Windows
------------------
1. Replace the repository contents with this folder.
2. Commit and push to GitHub.
3. In Codemagic select the YAML workflow “FoxNetwork TestFlight RELEASE”.
4. Confirm the log says: flutter build ipa --release.
5. Wait for build 11 to finish processing in TestFlight.
6. Delete all old/manual FoxNetwork installs from the iPhone.
7. Install build 11 from TestFlight only.

Important
---------
This package was statically checked and cleaned in a Linux environment.
The final iOS compilation/signing still has to run on Codemagic or a Mac because Xcode is unavailable on Windows/Linux.
