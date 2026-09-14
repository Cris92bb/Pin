#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

TARGET="${1:-all}"

case "$TARGET" in
  linux|web|all) ;;
  *)
    echo "Usage: $0 [linux|web|all]" >&2
    exit 1
    ;;
esac

if [ "$TARGET" = "linux" ] || [ "$TARGET" = "all" ]; then
  echo "Building Pin release bundle for Linux..."
  flutter build linux --release
  ARCH_DIR="$(uname -m | sed -e 's/x86_64/x64/' -e 's/aarch64/arm64/')"
  echo "Linux release binary located at:"
  echo "$DIR/build/linux/$ARCH_DIR/release/bundle/pin"
fi

if [ "$TARGET" = "web" ] || [ "$TARGET" = "all" ]; then
  echo "Building optimized Pin release bundle for Web..."
  bash "$DIR/build_web.sh"
fi

echo "All requested builds complete!"
