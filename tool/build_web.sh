#!/bin/bash
set -x

# Install Flutter
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="`pwd`/flutter/bin:$PATH"

# Decode Secret Files (for Vercel)
if [ -n "$FIREBASE_OPTIONS_BASE64" ]; then
  echo "$FIREBASE_OPTIONS_BASE64" | base64 --decode > lib/firebase_options.dart
fi

# Get Dependencies
echo "Getting dependencies..."
flutter pub get
(cd packages/pinball_audio && flutter pub get)
(cd packages/pinball_components && flutter pub get)
(cd packages/pinball_theme && flutter pub get)
# wallet_repository and others are gone in base fork

# Generate Assets
echo "Generating assets..."
flutter gen-l10n
# Root Project
flutter pub run build_runner build --delete-conflicting-outputs
# Packages
(cd packages/pinball_audio && flutter pub run build_runner build --delete-conflicting-outputs)
(cd packages/pinball_components && flutter pub run build_runner build --delete-conflicting-outputs)
(cd packages/pinball_theme && flutter pub run build_runner build --delete-conflicting-outputs)

# Build Web
# Using --base-href / to ensure index.html placeholders are replaced.
# Using --web-renderer=html for maximum compatibility.
flutter --version
flutter build web --release --no-wasm-dry-run --base-href=/ --web-renderer=html
