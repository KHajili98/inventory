#!/usr/bin/env zsh
# Run Flutter web with Chrome security disabled so cross-origin API calls work
# during local development. Never use this in production.
flutter run \
  -d chrome \
  --web-browser-flag "--disable-web-security" \
  --web-browser-flag "--user-data-dir=/tmp/flutter-chrome-dev"

# ── Release build (output → build/web) ──────────────────────────────────────
# flutter build web --release
