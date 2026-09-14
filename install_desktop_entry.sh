#!/usr/bin/env bash
# Installs the Linux launcher (pin.desktop) and icon for the current user,
# pointing the launcher at this checkout's launch_pin.sh.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
APPS_DIR="$DATA_DIR/applications"
ICON_DIR="$DATA_DIR/icons/hicolor/512x512/apps"

mkdir -p "$APPS_DIR" "$ICON_DIR"
if [ -f "$DIR/assets/icons/pin.png" ]; then
  cp "$DIR/assets/icons/pin.png" "$ICON_DIR/pin.png"
elif [ -f "$DIR/web/icons/Icon-512.png" ]; then
  cp "$DIR/web/icons/Icon-512.png" "$ICON_DIR/pin.png"
fi

# Escape characters that are special in the sed replacement.
ESCAPED_DIR="$(printf '%s' "$DIR" | sed 's/[&|\\]/\\&/g')"
sed "s|@APP_DIR@|$ESCAPED_DIR|g" "$DIR/pin.desktop" > "$APPS_DIR/pin.desktop"
chmod +x "$DIR/launch_pin.sh" "$APPS_DIR/pin.desktop"

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$APPS_DIR" || true
fi

echo "Installed launcher: $APPS_DIR/pin.desktop"
