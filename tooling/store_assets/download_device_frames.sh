#!/usr/bin/env bash
# Vendor PNG device frames from device-frames-media (see store/ATTRIBUTION.md).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BASE="https://raw.githubusercontent.com/jonnyjackson26/device-frames-media/main/device-frames-output"

download_set() {
  local src_path=$1
  local dest_name=$2
  local dest="$ROOT/device-frames/$dest_name"
  mkdir -p "$dest"
  for f in frame.png mask.png template.json; do
    echo "→ $dest_name/$f"
    curl -fsSL "$BASE/$src_path/$f" -o "$dest/$f"
  done
}

download_set "Apple%20iPhone/16%20Pro%20Max/Black%20Titanium" \
  "iphone-16-pro-max-black-titanium"
download_set "Android%20Phone/Pixel%209%20Pro/Obsidian" \
  "pixel-9-pro-obsidian"
download_set "Android%20Tablet/Pixel%20Tablet/Hazel" \
  "pixel-tablet-hazel"

echo "Device frames ready under tooling/store_assets/device-frames/"
