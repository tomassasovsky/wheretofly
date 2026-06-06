# Zone Polygon Debugging Guide
Branch: `claude/portainer-stack-deploy-error-LVcBR`

## What Was Changed (4 commits, 7d73edc → bec0e09)

### Goal
Render airspace zones as their real polygon shapes instead of circle approximations.

### Pipeline overview
```
ANAC AIP text
  → tooling/anac_aip_parser (Dart tool, new)
  → backend/data/anac_aip_zones.geojson (generated file, must exist)
  → ZoneIngestService (reads file, merges, emits Polygon GeoJSON)
  → backend/data/zones.geojson (served via GET /v1/zones)
  → BackendZonesApiClient._parseGeoJson (parses Polygon geometry)
  → ZoneData.polygon (List<List<double>>?)
  → FlightRulesRepository._toFlyZone → FlyZone.boundary (List<LatLng>?)
  → MapZoneOverlayBuilder → MapZoneCircleStyle.boundary
  → MapZoneFlutterMapMarkers.build → PolygonLayer + CircleLayer
  → flutter_map_layer.dart _buildZoneLayers()
```

---

## Step-by-Step Verification

### Step 1 — Generate the AIP zones file
```sh
cd wheretofly/tooling/anac_aip_parser
dart pub get
dart run bin/generate_zones.dart --out ../../backend/data/anac_aip_zones.geojson
```
Expected output:
```
[OK]  anac_tma_baires — 8 vertices
[OK]  anac_ctr_saez — 8 vertices
[OK]  anac_ctr_sabe — 8 vertices
[OK]  anac_ctr_saav — ~362 vertices   (now fixed, was 1)
[OK]  anac_ctr_saco — ~362 vertices
... (8 more circular CTRs)
[OK]  anac_sar_01 — 5 vertices
Wrote backend/data/anac_aip_zones.geojson  (12 zones, 0 skipped)
```
**Check**: `cat backend/data/anac_aip_zones.geojson | grep '"type": "Polygon"' | wc -l` should return 12.

---

### Step 2 — Restart the backend
The backend must be running the code from this branch. Verify:
```sh
# In the backend directory
dart pub get
dart run bin/server.dart   # or however you start it locally
```

**Check the working directory**: The default `aipZonesPath` is `data/anac_aip_zones.geojson` (relative). The backend resolves this relative to wherever `dart run` is executed from. If you run from `backend/`, it looks for `backend/data/anac_aip_zones.geojson`. If from repo root, it looks for `data/anac_aip_zones.geojson`.

To force an absolute path, set the env var:
```sh
AIP_ZONES_PATH=/absolute/path/to/wheretofly/backend/data/anac_aip_zones.geojson dart run bin/server.dart
```

---

### Step 3 — Trigger zone ingest
```sh
curl -s -X POST http://localhost:8080/v1/cron/zone_ingest \
  -H "x-cron-secret: <your JWT_SECRET>" | jq .
```
Expected: `{"zoneVersion":"2026-06-..."}` (a fresh timestamp).

**Check the output feed**:
```sh
cat backend/data/zones.geojson | python3 -c "
import json, sys
fc = json.load(sys.stdin)
polys = [f for f in fc['features'] if f['geometry']['type'] == 'Polygon']
circles = [f for f in fc['features'] if f['geometry']['type'] == 'Point']
print(f'Polygons: {len(polys)}, Points: {len(circles)}')
for p in polys[:5]:
    print(' -', p['properties']['name'], len(p['geometry']['coordinates'][0]), 'vertices')
"
```
Expected: at least 12 Polygons including `TMA BAIRES`, `CTR EZEIZA`, `CTR AEROPARQUE`.

---

### Step 4 — Verify the frontend receives polygon data
Add a temporary debug print to `BackendZonesApiClient._parseGeoJson`:
```dart
// In packages/backend_zones_api_client/lib/src/backend_zones_api_client.dart
// Inside _parseGeoJson, after parsing:
final polyCount = zones.where((z) => z.polygon != null).length;
debugPrint('Zones loaded: ${zones.length}, with polygon: $polyCount');
```
Expected: `with polygon: 12` (or however many non-circle zones are in the feed).

If `with polygon: 0`, the zones are being parsed as Point geometry — the ingest didn't run with the new code, or `zones.geojson` still has the old format.

---

### Step 5 — Verify FlyZone.boundary is populated
Add a debug print in `FlightRulesRepository._toFlyZone` or in `MapZoneFlutterMapMarkers.build`:
```dart
// In lib/map/map_zone_flutter_map_markers.dart, inside build():
debugPrint('Styles: ${styles.length}, polygon-backed: ${styles.where((s) => s.boundary != null).length}');
```
Expected: `polygon-backed: 12`.

If `polygon-backed: 0` but step 4 showed polygons, check `FlightRulesRepository._toFlyZone`:
```dart
// packages/flight_rules_repository/lib/src/flight_rules_repository.dart ~line 121
boundary: data.polygon
    ?.map((p) => LatLng(p[1], p[0]))
    .toList(growable: false),
```
Make sure this line is present (it was added in commit 7d73edc).

---

### Step 6 — Verify PolygonLayer is being built
Add a debug print in `_buildZoneLayers`:
```dart
// lib/map/view/widgets/flutter_map_layer.dart
List<Widget> _buildZoneLayers() {
  final layers = MapZoneFlutterMapMarkers.build(...);
  debugPrint('Zone layers: ${layers.polygons.length} polygons, ${layers.circles.length} circles');
  ...
```
Expected: `polygons: 12, circles: ~700` (or however many bundled/MADHEL zones).

If `polygons: 0`: boundary is not flowing through MapZoneOverlayBuilder. Check:
```dart
// lib/map/map_zone_overlay_builder.dart
return MapZoneCircleStyle(
  ...
  boundary: zone.boundary,   // ← this line must be present
);
```

---

## Most Likely Failure Points

### A. Old zones.geojson still being served (most likely)
The backend was not restarted with the new code before the ingest ran, so `zones.geojson` was regenerated by the OLD ingest code (which still emits Point geometry).

**Fix**: Restart backend with new code → re-trigger ingest → check zones.geojson has `"type": "Polygon"` entries.

### B. aipZonesPath file not found
The file `data/anac_aip_zones.geojson` is not found because the working directory doesn't match. The ingest skips it silently and produces only circle zones.

**Fix**: Use `AIP_ZONES_PATH=/absolute/path` env var, or check the backend logs for any hint it tried to read the file.

### C. App cached old zone data
The Flutter app's local storage (`zone_feed_body`) still has the old circle-only feed. ETag caching means it won't re-fetch unless the server's ETag changes (it does, since `zone_ingest` bumps the version and ETag).

**Fix**: Force a fresh sync by clearing app storage, or in debug mode call `BackendZonesApiClient.fetchZones()` directly (it will ignore the cached ETag if the server returns 200).

### D. PolygonLayer import missing
`flutter_map_layer.dart` imports `flutter_map` — make sure `PolygonLayer` and `Polygon` are in scope. In flutter_map 7.x they are exported from `package:flutter_map/flutter_map.dart`.

---

## Key File Locations

| File | Role |
|---|---|
| `tooling/anac_aip_parser/lib/src/zone_database.dart` | AIP boundary text (edit to add/fix zones) |
| `tooling/anac_aip_parser/bin/generate_zones.dart` | Generator CLI |
| `backend/data/anac_aip_zones.geojson` | Generated file (commit after re-generating) |
| `backend/lib/services/zone_ingest_service.dart` | Merges AIP file + OpenAIP + MADHEL + bundled |
| `backend/data/zones.geojson` | Served feed — inspect this to confirm polygon geometry |
| `packages/backend_zones_api_client/lib/src/backend_zones_api_client.dart` | Frontend GeoJSON parser |
| `packages/zones_api_client/lib/src/models/zone_data.dart` | ZoneData.polygon field |
| `packages/flight_rules_repository/lib/src/models/fly_zone.dart` | FlyZone.boundary + point-in-polygon |
| `lib/map/map_zone_circle_style.dart` | MapZoneCircleStyle.boundary |
| `lib/map/map_zone_flutter_map_markers.dart` | Splits into PolygonLayer / CircleLayer |
| `lib/map/view/widgets/flutter_map_layer.dart` | _buildZoneLayers() — renders both |

---

## Quick Sanity Check Script

Run from repo root after step 3:
```sh
python3 -c "
import json
fc = json.load(open('backend/data/zones.geojson'))
features = fc['features']
polys = [f for f in features if f['geometry']['type'] == 'Polygon']
points = [f for f in features if f['geometry']['type'] == 'Point']
print(f'Total features: {len(features)}')
print(f'Polygons: {len(polys)}')
print(f'Points (circles): {len(points)}')
for p in polys:
    n = p['properties']['name']
    verts = len(p['geometry']['coordinates'][0])
    lat = p['properties']['latitude']
    lon = p['properties']['longitude']
    print(f'  {n}: {verts} vertices, centre ({lat:.3f}, {lon:.3f})')
"
```
If `Polygons: 0` → ingest ran with old code. Restart backend and re-ingest.
If `Polygons: 12` but nothing shows in app → issue is in the frontend parse/render path (Steps 4–6).

---

## Expected Visual Result

- **CTR EZEIZA**: not circular — has straight-line segments on one side, 20 NM arc on the other
- **TMA BAIRES**: large sweep, roughly circular but defined by 55 NM arc + straight vertices
- **CTR AEROPARQUE**: has a straight eastern boundary (Río de la Plata / FIR line)
- **SAR 01**: rectangular (4 straight-line vertices)
- All other CTRs (CÓRDOBA, MENDOZA, etc.): ~360-vertex true circles (visually circular but geometrically exact)
