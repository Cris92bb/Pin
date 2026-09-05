#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "Building Pin release bundle for Linux..."
flutter build linux --release

echo "Build complete! Release binary located at:"
echo "$DIR/build/linux/x64/release/bundle/pin"
