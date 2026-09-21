#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

# pub get recreates the Swift package with Flutter's default iOS minimum.
# Configure it for Runner before Xcode resolves the Firebase dependencies.
# https://github.com/flutter/flutter/issues/186804
flutter pub get
flutter build ios --config-only --debug --no-codesign --no-pub

echo "iOS dependencies and build configuration are ready. Open ios/Runner.xcworkspace."
