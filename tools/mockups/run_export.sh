#!/usr/bin/env bash
# Helper script to run the mockup exporter on macOS
set -e

echo "Running mockup exporter on macOS..."
flutter run -d macos --target=lib/tools/mockup_exporter.dart
