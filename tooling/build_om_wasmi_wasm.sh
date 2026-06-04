#!/usr/bin/env bash
# Rebuild om_reader_wasm_wasmi.wasm (no WebAssembly SIMD) for iOS / Wasmi.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG="$ROOT/tooling/om-wasm-build/typescript-omfiles/packages/file-format-wasm"
if [[ ! -d "$PKG/om-file-format" ]]; then
  git clone --recursive --depth 1 https://github.com/open-meteo/typescript-omfiles.git \
    "$ROOT/tooling/om-wasm-build/typescript-omfiles"
fi
cd "$PKG"
docker run --rm -v "$(pwd):/src" -u "$(id -u):$(id -g)" emscripten/emsdk:4.0.12 \
  make -C /src scalar-wasm
cp dist/om_reader_wasm.scalar.wasm "$ROOT/assets/om/om_reader_wasm_wasmi.wasm"
echo "Wrote assets/om/om_reader_wasm_wasmi.wasm"
echo "Note: verify with: dart run tooling/om_smoke/bin/smoke.dart $ROOT $ROOT/assets/om/om_reader_wasm_wasmi.wasm"
