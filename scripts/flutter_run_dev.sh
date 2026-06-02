#!/usr/bin/env bash
# Runs Flutter with the Mac LAN IP so physical iOS/Android devices can reach
# the local Dart Frog backend (localhost on the phone is not your Mac).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IP="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true)"

if [[ -z "${IP}" ]]; then
  echo "Could not detect LAN IP. Pass API_BASE_URL manually:" >&2
  echo "  flutter run --dart-define=API_BASE_URL=http://<your-ip>:8080" >&2
  exit 1
fi

API_BASE_URL="http://${IP}:8080"
echo "Using API_BASE_URL=${API_BASE_URL}"

cd "${ROOT}"
exec flutter run --dart-define="API_BASE_URL=${API_BASE_URL}" "$@"
