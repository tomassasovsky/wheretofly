---
date: 2026-06-17
topic: airspace-verdict-accuracy
---

# Super-High-Accuracy Airspace Verdicts

## What We're Building

A program to raise the **legal correctness** of the app's "can I fly here?" verdict
from "good at zone scale" to "trustworthy near every edge — horizontally,
vertically, and in time." Today a verdict is a binary `bool` derived from
even-odd point-in-polygon (exterior ring only, raw lon/lat) plus an altitude
overlap check that **defaults ground elevation to 0**, with no notion of GPS
uncertainty or time-bounded restrictions. We will evolve the existing
`FlightRulesRepository` pipeline through **additive, independently-shippable
layers** so that verdicts account for terrain, true geometry, active NOTAMs, and
the pilot's own position uncertainty — and degrade **fail-safe with an explicit
"uncertain — verify manually" state** rather than a false "yes."

The constraint that shapes every layer: **offline must stay correct**. All four
accuracy axes must produce sound verdicts with no network, with clear staleness
indicators when the cached data is old.

## Why This Approach

Three strategies were considered:

- **A — Incremental layered hardening (chosen).** Keep VGV layering and
  `FlightRulesRepository` as the verdict authority; add accuracy as additive
  layers, each shippable and testable on its own. Lowest regression risk,
  consistent with the codebase, YAGNI-friendly.
- **B — Dedicated `airspace_engine` package.** One package owning a single rich
  query. Cleaner separation but a bigger upfront refactor; its spatial index is
  premature until zone counts are large.
- **C — Precomputed accuracy tiles.** Backend bakes per-cell constraint rasters;
  client does O(1) offline lookup. Fast and simple, but raster resolution caps
  spatial accuracy — which directly fights the "super high accuracy" goal.

**A wins** because the single highest-leverage change — making verdicts carry
confidence and reasons instead of a bare `bool` — is what unlocks the fail-safe
uncertainty band the user chose, and it can be introduced without rewriting the
data sources. B's separation and C's raster can be adopted later if perf or
client-compute pressure demands it; neither is needed now.

## Scope — the four accuracy axes (all in scope)

Ordered by recommended sequencing (highest correctness-per-effort first):

1. **Confidence-aware verdict model (keystone).** Replace `bool contains()` /
   `bool overlapsAltitudeRange()` with a structured result
   `Verdict { status, confidence, reasons[] }` where `status ∈ {allowed,
   conditional, blocked, uncertain}`. Every downstream layer feeds reasons and
   can downgrade `status` to `uncertain`. This is what makes "fail-safe +
   explicit uncertainty band" representable end-to-end.

2. **Vertical / terrain (AGL↔MSL).** New offline data package providing a
   quantized DEM for Argentina (e.g. Copernicus GLO-30 / SRTM, downsampled and
   tiled) so `groundElevationMsl` is real instead of `0`. Fixes the silent
   altitude bug. Coarse/edge DEM cells contribute an `uncertain` reason.

3. **Horizontal geometry.** Polygon **holes** (donut zones), **geodesic**
   point-in-polygon, a **GPS-error buffer** around boundaries that triggers
   `uncertain` when the query point is within margin, and **real aerodrome
   polygons** replacing MADHEL default-radius circles where AIP data exists.

4. **Temporal (NOTAMs / TFRs).** Backend parses Argentine NOTAMs into
   time-bounded zones merged into the same `/v1/zones` feed; client caches the
   snapshot with a sync timestamp. Staleness beyond a threshold downgrades
   affected verdicts to `uncertain` with an explicit "NOTAM data N days old"
   reason.

## Key Decisions

- **All four accuracy axes are in scope** (vertical/terrain, horizontal
  geometry, temporal/NOTAM, query-time GPS uncertainty): "super high accuracy"
  was defined as comprehensive, not one dimension.
- **Offline must stay correct.** Rules out a server-authoritative design. DEM
  tiles and a last-synced NOTAM snapshot are bundled/cached client-side; the app
  shows staleness rather than silently degrading.
- **Fail-safe + explicit uncertainty band.** When near a boundary within GPS
  error, terrain data is coarse, or the NOTAM snapshot is stale, the verdict
  defaults conservative AND surfaces a distinct `uncertain — verify manually`
  state with the specific reason and how to resolve it. Not a flat "no."
- **Approach A — incremental layered hardening.** Evolve `FlightRulesRepository`
  through additive layers; keep VGV one-directional layering
  (`data ← repository ← business logic ← presentation`). No big-bang rewrite.
- **Confidence-aware verdict model is built first** — it is the prerequisite
  that lets every other layer express degradation honestly.

## Open Questions

- **DEM source & size budget.** Which dataset (Copernicus GLO-30 vs SRTM), what
  resolution/quantization, and what bundle-size ceiling is acceptable for the
  app? Bundle nationwide vs download-on-first-use per region?
- **NOTAM source authority.** Is there a machine-readable Argentine NOTAM/AIP
  feed (ANAC / FAA NOTAM API / ICAO), and what's its licensing and update
  cadence? Parsing reliability is the main risk for axis 4.
- **Provenance / legal source of truth.** For verdicts, do we anchor strictly on
  official ANAC AIP and treat OpenAIP community data as supplementary/validation
  only? (Affects which geometry "wins" on conflict.)
- **GPS accuracy input.** Does the location layer already expose horizontal
  accuracy (metres) per fix, or does the buffer need a conservative default?
- **Staleness thresholds.** How old is "too old" for the NOTAM snapshot before a
  verdict goes `uncertain`? Per-category (e.g. TFRs stricter than baseline)?
- **UX for the third state.** How does `uncertain` render on the map and in the
  verdict card without undermining trust in clear yes/no cases?
- **Migration of the verdict model.** Every current consumer of `contains()` /
  `overlapsAltitudeRange()` (and the map overlay) must move to the new model in
  one coordinated change — scope that as the first PR.
