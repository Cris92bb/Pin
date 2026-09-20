#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

PORT="${1:-5000}"
echo "======================================================"
echo " Launching Pin on Flutter Web (Chrome)"
echo " Origin: http://localhost:$PORT"
echo "======================================================"

exec flutter run -d chrome --web-port "$PORT"
