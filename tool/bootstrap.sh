#!/usr/bin/env bash
# Generates the android/ and ios/ folders and applies Gharcha's native settings, icons and splash.
set -euo pipefail
cd "$(dirname "$0")/.."
flutter create --org app --project-name gharcha --platforms android,ios .
rm -f test/widget_test.dart
python3 tool/patch_platforms.py
flutter pub get
