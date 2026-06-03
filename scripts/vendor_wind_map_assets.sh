#!/usr/bin/env bash
# Re-download vendored MapLibre GL JS + Open-Meteo weather-map-layer into assets/wind_map/.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/assets/wind_map"
mkdir -p "$DEST"
curl -fsSL -o "$DEST/maplibre-gl.css" \
  "https://unpkg.com/maplibre-gl@4.7.1/dist/maplibre-gl.css"
curl -fsSL -o "$DEST/maplibre-gl.js" \
  "https://unpkg.com/maplibre-gl@4.7.1/dist/maplibre-gl.js"
curl -fsSL -o "$DEST/weather-map-layer.js" \
  "https://unpkg.com/@openmeteo/weather-map-layer@0.0.19/dist/index.js"
echo "Vendored wind map assets in $DEST"
