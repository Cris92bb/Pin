#!/usr/bin/env bash
set -e

DIR="/home/cris92bb/Desktop/Projects/Pin"
RELEASE_BIN="$DIR/build/linux/x64/release/bundle/pin"
DEBUG_BIN="$DIR/build/linux/x64/debug/bundle/pin"

# Pick the newest build between release and debug, or build release if missing
TARGET_BIN=""
if [ -f "$RELEASE_BIN" ] && [ -f "$DEBUG_BIN" ]; then
    if [ "$DEBUG_BIN" -nt "$RELEASE_BIN" ]; then
        TARGET_BIN="$DEBUG_BIN"
    else
        TARGET_BIN="$RELEASE_BIN"
    fi
elif [ -f "$RELEASE_BIN" ]; then
    TARGET_BIN="$RELEASE_BIN"
elif [ -f "$DEBUG_BIN" ]; then
    TARGET_BIN="$DEBUG_BIN"
else
    cd "$DIR"
    flutter build linux --release
    TARGET_BIN="$RELEASE_BIN"
fi

cd "$(dirname "$TARGET_BIN")"
exec "$TARGET_BIN" "$@"
