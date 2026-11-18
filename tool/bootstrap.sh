#!/usr/bin/env bash
# Generates the android/ and ios/ folders, applies Kharchili's native settings and renders icons and splash.
set -euo pipefail
cd "$(dirname "$0")/.."
flutter create --org app --project-name kharchili --platforms android,ios .
rm -f test/widget_test.dart
python3 tool/patch_platforms.py
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
