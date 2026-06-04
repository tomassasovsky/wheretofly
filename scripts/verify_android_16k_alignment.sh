#!/usr/bin/env bash
# Verify 64-bit native libraries in an APK/AAB are 16 KB ELF-aligned (arm64-v8a, x86_64).
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <app-release.apk|app-release.aab>" >&2
  exit 1
fi

ARTIFACT="$1"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NDK_VERSION="${ANDROID_NDK_VERSION:-28.2.13676358}"

if [[ -z "${ANDROID_NDK_HOME:-}" ]]; then
  if [[ -n "${ANDROID_HOME:-}" && -d "$ANDROID_HOME/ndk/$NDK_VERSION" ]]; then
    ANDROID_NDK_HOME="$ANDROID_HOME/ndk/$NDK_VERSION"
  elif [[ -d "$HOME/Library/Android/sdk/ndk/$NDK_VERSION" ]]; then
    ANDROID_NDK_HOME="$HOME/Library/Android/sdk/ndk/$NDK_VERSION"
  else
    echo "Set ANDROID_NDK_HOME or ANDROID_HOME (need NDK $NDK_VERSION)." >&2
    exit 1
  fi
fi

OBJDUMP="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$(uname | tr '[:upper:]' '[:lower:]')-x86_64/bin/llvm-objdump"
if [[ ! -x "$OBJDUMP" ]]; then
  OBJDUMP="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump"
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [[ "$ARTIFACT" == *.aab ]]; then
  if ! command -v bundletool >/dev/null 2>&1; then
    echo "bundletool required to inspect AAB; pass a release APK instead." >&2
    exit 1
  fi
  bundletool build-apks --bundle="$ARTIFACT" --output="$TMP/out.apks" --mode=universal >/dev/null
  unzip -q "$TMP/out.apks" -d "$TMP"
  APK="$TMP/universal.apk"
else
  APK="$ARTIFACT"
fi

unzip -q "$APK" "lib/*/*.so" -d "$TMP" 2>/dev/null || true

FAILED=0
for abi in arm64-v8a x86_64; do
  shopt -s nullglob
  for so in "$TMP/lib/$abi"/*.so; do
    name="$(basename "$so")"
    min_align=99
    while read -r line; do
      align="$(printf '%s' "$line" | sed -n 's/.*align 2\*\*\([0-9][0-9]*\).*/\1/p')"
      if [[ -n "$align" && "$align" -lt "$min_align" ]]; then
        min_align=$align
      fi
    done < <("$OBJDUMP" -p "$so" 2>/dev/null | rg "LOAD" | rg -o "align 2\*\*[0-9]+" || true)
    if [[ "$min_align" -lt 14 ]]; then
      echo "UNALIGNED  $abi/$name  (min LOAD align 2**$min_align, need 2**14+)"
      FAILED=1
    else
      echo "ALIGNED    $abi/$name  (min LOAD align 2**$min_align)"
    fi
  done
done

if [[ "$FAILED" -ne 0 ]]; then
  echo "16 KB check failed. Rebuild wasm_run: $ROOT/scripts/rebuild_wasm_run_android_16k.sh" >&2
  exit 1
fi

SDK_BUILD_TOOLS="${ANDROID_HOME:-$HOME/Library/Android/sdk}/build-tools/36.0.0"
ZIPALIGN="$SDK_BUILD_TOOLS/zipalign"
if [[ -x "$ZIPALIGN" ]]; then
  "$ZIPALIGN" -c -P 16 -v 4 "$APK" | tail -1
fi

echo "All 64-bit native libraries are 16 KB compatible."
