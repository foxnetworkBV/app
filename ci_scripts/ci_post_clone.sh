#!/bin/sh
# Bootstrap Flutter dependencies before Xcode Cloud resolves the workspace.
set -eu

FLUTTER_VERSION="3.47.2"
FLUTTER_HOME="$HOME/flutter"

git clone --depth 1 --branch "$FLUTTER_VERSION" \
  https://github.com/flutter/flutter.git "$FLUTTER_HOME"

export PATH="$FLUTTER_HOME/bin:$PATH"

cd "$CI_WORKSPACE"
flutter precache --ios
flutter pub get

cd ios
pod install
