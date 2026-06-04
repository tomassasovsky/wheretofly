#!/usr/bin/env bash
# Capture raw simulator screenshots and compose store marketing images.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

DEVICE="${STORE_SCREENSHOT_DEVICE:-iPhone 16 Pro Max}"
STORE_DIR="$ROOT/store"
export STORE_SCREENSHOT_ROOT="$ROOT"

capture_locale() {
  local locale=$1
  local raw_dir="$ROOT/docs/screenshots/$locale"
  mkdir -p "$raw_dir"
  export STORE_SCREENSHOT_DIR="$raw_dir"

  echo "→ Capturing ($locale) on simulator: $DEVICE"
  flutter drive \
    --driver=test_driver/integration_test.dart \
    --target=integration_test/store_screenshot_test.dart \
    -d "$DEVICE" \
    --dart-define=STORE_SCREENSHOT_AUTO_SELECT=true \
    --dart-define=STORE_SCREENSHOT_LOCALE="$locale"

  if ! compgen -G "$raw_dir"/0*.png > /dev/null; then
    echo "error: no screenshots in $raw_dir" >&2
    exit 1
  fi
}

capture_locale en
capture_locale es

if [[ ! -f "$ROOT/tooling/store_assets/device-frames/iphone-16-pro-max-black-titanium/frame.png" ]]; then
  echo "→ Downloading device frame PNGs"
  "$ROOT/tooling/store_assets/download_device_frames.sh"
fi

echo "→ Composing store assets (2× render)"
python3 "$ROOT/tooling/store_assets/generate_store_images.py" \
  --store-dir "$STORE_DIR" \
  --locale all

echo "Done. Upload from:"
echo "  iOS EN: $STORE_DIR/marketing/en/ios_6.7/"
echo "  iOS ES: $STORE_DIR/marketing/es/ios_6.7/"
echo "  Android EN: $STORE_DIR/marketing/en/android_phone/"
echo "  Android ES: $STORE_DIR/marketing/es/android_phone/"
