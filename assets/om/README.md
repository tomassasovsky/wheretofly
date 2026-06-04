# Open-Meteo OM reader WASM (GPL-2.0-only)

- `om_reader_wasm.wasm` — SIMD build (Wasmtime / desktop / Android arm64-v8a)
- `om_reader_wasm_wasmi.wasm` — scalar build for Wasmi (iOS) — **decode is currently broken**

Rebuild the Wasmi artifact: `tooling/build_om_wasmi_wasm.sh` (requires Docker).

## Wind layer (gust + direction arrows)

- **Gust raster** uses `wind_gusts_10m` and the Open-Meteo `wind` colorscale.
- **Direction arrows** use `wind_u_component_10m` and `wind_v_component_10m` from the same `.om` file.

Verify u/v decode: `dart run tooling/om_smoke/bin/uv_smoke.dart` (from `tooling/om_smoke`).

## iOS / iPhone

`wasm_run_flutter` uses **Wasmi without SIMD** on iOS, so the app loads `om_reader_wasm_wasmi.wasm`.
That build does not yet produce correct gust values (see `dart run tooling/om_smoke/bin/smoke.dart`).

**Workaround for simulator/device testing:**

1. On your dev machine (Mac or Linux, once): `dart run wasm_run:setup` from `tooling/om_tile_server` or `tooling/om_smoke`
2. Start tiles: `dart run tooling/om_tile_server/bin/server.dart` (from repo root; uses SIMD wasm)
   - `GET /<z>/<x>/<y>.png` — gust raster
   - `GET /<z>/<x>/<y>.json` — sparse u/v arrow samples
3. Run the app with: `--dart-define=WIND_TILE_BASE_URL=http://127.0.0.1:8765` (simulator) or your host’s LAN IP on a physical device.
