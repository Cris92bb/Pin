#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "======================================================"
echo " Building Optimized Pin Release for Flutter Web"
echo " Target: WebAssembly (WASM-GC / Skwasm) + JS Fallback"
echo " Optimization Level: -O4 (Aggressive minification & inlining)"
echo " Icon Tree-Shaking: Enabled"
echo "======================================================"

# Build Flutter Web with WASM and aggressive optimizations
flutter build web \
  --release \
  --wasm \
  --optimization-level=4 \
  --strip-wasm \
  --no-source-maps \
  --tree-shake-icons

echo ""
echo "Compressing static assets with gzip (-9) for ultra-fast CDN delivery..."
if command -v gzip >/dev/null 2>&1; then
  find build/web -type f \( -name "*.wasm" -o -name "*.js" -o -name "*.json" -o -name "*.html" -o -name "*.css" \) -exec gzip -k -9 -f {} +
else
  echo "gzip not found: skipping pre-compression."
fi

echo ""
echo "======================================================"
echo " Optimized Web Build Summary:"
echo " Output Directory: $DIR/build/web"
echo "------------------------------------------------------"
ls -lh build/web/main.dart.wasm build/web/main.dart.wasm.gz build/web/main.dart.js build/web/main.dart.js.gz build/web/flutter_bootstrap.js 2>/dev/null || true
echo "======================================================"
echo "Done! The web bundle is ready for production deployment."
