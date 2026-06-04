#!/usr/bin/env bash
# Rebuild wasm_run's Android libwasm_run_dart.so with 16 KB ELF alignment (Play requirement).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/tooling/wasm_run_android_16k"
JNI_OUT="$ROOT/android/app/src/main/jniLibs"
NDK_VERSION="${ANDROID_NDK_VERSION:-28.2.13676358}"

if [[ -z "${ANDROID_NDK_HOME:-}" ]]; then
  if [[ -n "${ANDROID_HOME:-}" && -d "$ANDROID_HOME/ndk/$NDK_VERSION" ]]; then
    export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/$NDK_VERSION"
  elif [[ -d "$HOME/Library/Android/sdk/ndk/$NDK_VERSION" ]]; then
    export ANDROID_NDK_HOME="$HOME/Library/Android/sdk/ndk/$NDK_VERSION"
  else
    echo "Set ANDROID_NDK_HOME or ANDROID_HOME (need NDK $NDK_VERSION)." >&2
    exit 1
  fi
fi

if ! command -v cargo-ndk >/dev/null 2>&1; then
  echo "Install cargo-ndk: cargo install cargo-ndk --locked" >&2
  exit 1
fi

for target in aarch64-linux-android x86_64-linux-android; do
  rustup target add "$target" >/dev/null 2>&1 || true
done

# Sync Rust sources from the published wasm_run package (bridge is already generated).
PUB_CACHE_DIR="${PUB_CACHE:-$HOME/.pub-cache}"
WASM_RUN_NATIVE="$PUB_CACHE_DIR/hosted/pub.dev/wasm_run-0.1.0+2/native"
if [[ ! -d "$WASM_RUN_NATIVE/src" ]]; then
  echo "wasm_run native sources not found in pub cache." >&2
  exit 1
fi
rsync -a --delete \
  --exclude target \
  --exclude Cargo.toml \
  --exclude build.rs \
  "$WASM_RUN_NATIVE/" "$BUILD_DIR/"
# Cargo.toml and build.rs are excluded from rsync and stay in BUILD_DIR.

export RUSTFLAGS='-C link-arg=-Wl,-z,max-page-size=16384 -C link-arg=-Wl,-z,common-page-size=16384'

cd "$BUILD_DIR"
rm -rf jniLibs
cargo ndk -t arm64-v8a -t x86_64 -o ./jniLibs build --release

mkdir -p "$JNI_OUT"
for abi in arm64-v8a x86_64; do
  mkdir -p "$JNI_OUT/$abi"
  cp -f "$BUILD_DIR/jniLibs/$abi/libwasm_run_dart.so" "$JNI_OUT/$abi/libwasm_run_dart.so"
done

echo "Installed 16 KB-aligned libwasm_run_dart.so to $JNI_OUT/{arm64-v8a,x86_64}"
