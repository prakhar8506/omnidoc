#!/bin/sh
# Play App Bundle with shrinking (Gradle) and Dart obfuscation.
# Symbols stay in build/symbols, which is gitignored. They are only for
# decoding crash stacks. They are not a patent and do not stop reverse engineering.
set -eu
cd "$(dirname "$0")/.."

if [ ! -f env/production.json ]; then
  echo "env/production.json is missing. Copy env/production.json.example and fill it in." >&2
  exit 1
fi

if [ ! -f android/key.properties ]; then
  echo "android/key.properties is missing. A Play release needs the upload keystore." >&2
  exit 1
fi

flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/symbols \
  --dart-define-from-file=env/production.json

echo "Bundle: build/app/outputs/bundle/release/app-release.aab"
echo "Keep build/symbols private. Upload the bundle only, not the symbol files."
