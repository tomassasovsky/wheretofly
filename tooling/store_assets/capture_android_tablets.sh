#!/usr/bin/env bash
# Capture tablet store screenshots — same integration test as phone/iOS.
#
# Prerequisites:
#   - Tablet_7_API_35 and/or Pixel_Tablet_API_36 AVDs (see store/README.md)
#   - One tablet emulator running, or let this script start each AVD in turn
#
# Usage:
#   ./tooling/store_assets/capture_android_tablets.sh
#   STORE_TABLET_BUCKETS=android_tablet_10 ./tooling/store_assets/capture_android_tablets.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export ANDROID_HOME PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
export STORE_SCREENSHOT_ROOT="$ROOT"

TABLET_7_AVD="${STORE_TABLET_7_DEVICE:-Tablet_7_API_35}"
TABLET_10_AVD="${STORE_TABLET_10_DEVICE:-Pixel_Tablet_API_36}"
TABLET_BUCKETS="${STORE_TABLET_BUCKETS:-android_tablet_7,android_tablet_10}"

log() { echo "[$(date +%H:%M:%S)] $*" >&2; }

avd_name() {
  adb -s "$1" emu avd name 2>/dev/null | head -1 | tr -d '\r'
}

serial_for_avd() {
  local want=$1
  while read -r serial state _; do
    [[ "$serial" == emulator-* && "$state" == device ]] || continue
    [[ "$(avd_name "$serial")" == "$want" ]] && echo "$serial" && return 0
  done < <(adb devices | tail -n +2)
  return 1
}

wait_for_boot() {
  local serial=$1
  adb -s "$serial" wait-for-device
  local n=0
  until [[ "$(adb -s "$serial" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]]; do
    n=$((n + 1))
    [[ $n -le 90 ]] || { echo "error: $serial did not boot" >&2; exit 1; }
    sleep 2
  done
}

start_avd() {
  local avd=$1
  if serial="$(serial_for_avd "$avd")"; then
    log "Using $serial ($avd)"
    echo "$serial"
    return 0
  fi
  log "Starting $avd …"
  "$ANDROID_HOME/emulator/emulator" -avd "$avd" -no-snapshot-load </dev/null >/tmp/"$avd".log 2>&1 &
  local n=0
  until serial="$(serial_for_avd "$avd")"; do
    n=$((n + 1))
    [[ $n -le 180 ]] || { echo "error: $avd not in adb; see /tmp/$avd.log" >&2; exit 1; }
    sleep 1
  done
  log "Booting $serial …"
  wait_for_boot "$serial"
  echo "$serial"
}

set_display() {
  local serial=$1 bucket=$2
  case "$bucket" in
    android_tablet_7)
      adb -s "$serial" shell wm size 1200x1920
      adb -s "$serial" shell wm density 213
      ;;
    android_tablet_10)
      adb -s "$serial" shell wm size 1600x2560
      adb -s "$serial" shell wm density 320
      ;;
    *) echo "error: unknown bucket $bucket" >&2; exit 1 ;;
  esac
  sleep 2
}

capture_locale() {
  local locale=$1 bucket=$2 serial=$3
  local raw_dir="$ROOT/docs/screenshots/$locale/$bucket"
  mkdir -p "$raw_dir"
  export STORE_SCREENSHOT_DIR="$raw_dir"

  adb -s "$serial" shell am force-stop dev.aquiles.wheretofly >/dev/null 2>&1 || true
  log "flutter drive ($locale / $bucket) on $serial"
  set +e
  flutter drive \
    --driver=test_driver/integration_test.dart \
    --target=integration_test/store_screenshot_test.dart \
    -d "$serial" \
    --dart-define=STORE_SCREENSHOT_LOCALE="$locale"
  local st=$?
  set -e

  local count
  count=$(find "$raw_dir" -maxdepth 1 -name '[0-9]*.png' 2>/dev/null | wc -l | tr -d ' ')
  if [[ "${count:-0}" -lt 6 ]]; then
    echo "error: expected 6 PNGs in $raw_dir, found ${count:-0} (exit $st)" >&2
    exit 1
  fi
  [[ $st -ne 0 ]] && log "flutter drive exited $st but $count screenshots saved"
}

run_bucket() {
  local bucket=$1 avd=$2
  local serial
  serial="$(start_avd "$avd")"
  set_display "$serial" "$bucket"
  capture_locale en "$bucket" "$serial"
  capture_locale es "$bucket" "$serial"
  adb -s "$serial" shell wm size reset >/dev/null 2>&1 || true
  adb -s "$serial" shell wm density reset >/dev/null 2>&1 || true
  adb -s "$serial" emu kill >/dev/null 2>&1 || true
  sleep 3
}

bucket_enabled() { [[ ",$TABLET_BUCKETS," == *",$1,"* ]]; }

if bucket_enabled android_tablet_7; then
  run_bucket android_tablet_7 "$TABLET_7_AVD"
fi
if bucket_enabled android_tablet_10; then
  run_bucket android_tablet_10 "$TABLET_10_AVD"
fi

log "Done. Compose with:"
log "  ./tooling/store_assets/capture_and_generate.sh  # or generate_store_images.py only"
