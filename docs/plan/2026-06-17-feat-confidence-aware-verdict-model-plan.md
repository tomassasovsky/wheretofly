---
title: "feat: confidence-aware flight verdict model"
type: feat
date: 2026-06-17
brainstorm: docs/brainstorm/2026-06-17-airspace-verdict-accuracy-brainstorm-doc.md
---

## feat: confidence-aware flight verdict model — Standard

> **Keystone PR** of the four-axis *Super-High-Accuracy Airspace Verdicts* program
> (see [brainstorm](../brainstorm/2026-06-17-airspace-verdict-accuracy-brainstorm-doc.md)).
> This PR ships **only the model and the coordinated consumer migration**. It adds
> no DEM, no NOTAM, and no geometry changes — those are axes 2–4, sequenced after
> this lands. The whole point of doing it first: make *uncertainty representable
> end-to-end* so later layers can downgrade a verdict honestly instead of forcing
> a false yes/no.

## Overview

Today a flight verdict is `enum FlightVerdict { allowed, allowedWithPermission, notAllowed }`
produced by [`FlightRulesRepository.assess()`](../../packages/flight_rules_repository/lib/src/flight_rules_repository.dart:84).
It has no way to say **"I don't know — verify manually."** When the repository is
built from an empty zone list (offline cache miss + empty fallback), `assess()`
silently returns `allowed` — a **false yes** in exactly the situation where we have
no data to stand on.

This plan introduces a structured, fail-safe result:

- A new `VerdictStatus { allowed, conditional, blocked, uncertain }` as the verdict authority.
- A typed `reasons[]` list, so every downstream accuracy layer (terrain, GPS buffer,
  NOTAM staleness) can **append a reason and downgrade `status` to `uncertain`**
  without re-migrating any consumer.
- A backward-compatible mapping back to the legacy `FlightVerdict` so the social
  wire format and already-persisted snapshots keep working.

All current consumers of the verdict move to the new model in **one coordinated
change** (the brainstorm's Open Question #7).

## Problem Statement / Motivation

- **Silent false "yes" with no data.** `assess()` on an empty repository returns
  `allowed` ([flight_rules_repository.dart:108-112](../../packages/flight_rules_repository/lib/src/flight_rules_repository.dart:108)).
  For a legal "can I fly here?" verdict this is the worst failure mode.
- **No representation of uncertainty.** The app already *knows* it is sometimes
  guessing — `FlightAssessment.hasMslAltitudeUncertainty`
  ([flight_assessment.dart:48](../../packages/flight_rules_repository/lib/src/models/flight_assessment.dart:48))
  drives a disclaimer banner — but the verdict itself can't carry that signal, so
  it can't be shared, color-coded, or reasoned about uniformly.
- **Future layers need a contract now.** Axes 2–4 (DEM, geometry/GPS, NOTAM) each
  need to say "this verdict is degraded because X." Without a `reasons[]` channel
  built first, every one of those PRs would re-touch every UI consumer. Building
  the channel once is the highest correctness-per-effort move (brainstorm §Scope).

## Proposed Solution

### Model shape (resolves flow-analysis blocker A1 / B2)

Add to `flight_assessment.dart`:

```dart
/// Confidence-aware verdict status. The verdict authority going forward.
enum VerdictStatus { allowed, conditional, blocked, uncertain }

/// Typed, l10n-keyed reasons a verdict carries. This PR defines ONLY the two it
/// emits. Future axes ADD their own value (e.g. `coarseTerrainData`,
/// `nearBoundaryGpsBuffer`, `notamSnapshotStale`) in the PR that emits it —
/// adding a `VerdictReason` value later costs ZERO consumer re-migration
/// (presentation switches on `status`, not on `VerdictReason`).
enum VerdictReason {
  zoneDataUnavailable,       // EMITTED here — repository built from empty list
  mslGroundElevationUnknown, // EMITTED here — maps existing hasMslAltitudeUncertainty
}
```

`FlightAssessment` gains `status` and `reasons`; `verdict` becomes a derived
compat getter (the constructor takes `required this.status`, **not** `verdict`):

```dart
final VerdictStatus status;          // NEW — the authority (constructor: required)
final List<VerdictReason> reasons;   // NEW — deduped, wrapped List.unmodifiable in the ctor

/// Back-compat: legacy 3-value verdict derived from [status].
/// uncertain maps to notAllowed (conservative) for old readers ONLY.
FlightVerdict get verdict => switch (status) {
      VerdictStatus.allowed     => FlightVerdict.allowed,
      VerdictStatus.conditional => FlightVerdict.allowedWithPermission,
      VerdictStatus.blocked     => FlightVerdict.notAllowed,
      VerdictStatus.uncertain   => FlightVerdict.notAllowed, // conservative
    };

/// Drives the existing MSL disclaimer banner — now reads [reasons]. The banner
/// widget keeps calling this getter (no widget churn); the getter is the only
/// thing that changes from "scan zones" to "scan reasons". `reasons` stays the
/// single source of truth; the banner is just a dedicated renderer for this one
/// reason (see "Reason rendering" below to avoid double-render).
bool get hasMslAltitudeUncertainty =>
    reasons.contains(VerdictReason.mslGroundElevationUnknown);
```

> **No `confidence` field in this PR.** It was cut as YAGNI — nothing here reads it
> (no UI, no logic, no snapshot). The `reasons` list already tells axis 2 a value is
> degraded (`mslGroundElevationUnknown` present). Axis 2 introduces `confidence`
> alongside the code that actually consumes it.
>
> **`FlightVerdict` stays** as a legacy/compat type. Presentation switches on the
> new `status`; only the social wire format reads `verdict`. Add a doc-comment on
> `FlightVerdict` directing new presentation code to switch on `status` instead.
>
> **`reasons` is deduped** in `assess()` before construction and wrapped in
> `List.unmodifiable` (matching `List.unmodifiable(_zones)` at
> [flight_rules_repository.dart:53](../../packages/flight_rules_repository/lib/src/flight_rules_repository.dart:53)).

### Verdict precedence ladder (resolves C1)

`assess()` assigns `status` by this deterministic ladder — **definite blocks are
never softened to `uncertain`**:

1. `blocked` — modality not permitted (`!modalityAllowed`, location-independent), OR
2. `blocked` — an overlapping zone the held permission cannot satisfy, OR
3. `uncertain` — a fail-safe data-quality reason applies (this PR: `zoneDataUnavailable`), OR
4. `conditional` — flyable, but only because the held permission/permit covers an overlapping zone, OR
5. `allowed` — clear.

### What this PR actually EMITS (scoped, trust-preserving)

| Trigger | Status | Reason | Notes |
|---|---|---|---|
| Repository built from an **empty zone list** | `uncertain` | `zoneDataUnavailable` | Fixes the silent false-yes. Today → `allowed`. |
| Overlapping zone uses **MSL limits** (no terrain yet) | **status unchanged** + reason | `mslGroundElevationUnknown` | Keeps today's banner behavior; **does not** flip every MSL zone to `uncertain`. The status downgrade lands in **axis 2** when DEM can distinguish coarse vs fine cells. Flagged so we don't flood users with "uncertain" before terrain data exists. |
| modality block / permission block / clear | `blocked`/`conditional`/`allowed` | — | Same outcomes as today, expressed via `status`. |

> **Decision (scope guard):** the keystone introduces the *mechanism* plus the one
> unambiguous fail-safe (no data). The MSL-without-terrain → `uncertain` downgrade
> is deliberately deferred to axis 2 to avoid "everything is uncertain" noise while
> ground elevation is still hardcoded to 0. The `mslGroundElevationUnknown` reason
> carries the signal until then.

### Presentation truth table (resolves A2/A3/A4/A5)

`status` is consumed in [`zone_detail_card.dart`](../../lib/map/view/widgets/zone_detail_card.dart)
via **exhaustive switches (no `default`)** so the next state addition is a compile error.

| `status` | Color | Icon | Headline (l10n) | Permit CTA | Controlled-airspace banner | Share button |
|---|---|---|---|---|---|---|
| `allowed` | `0xFF2E7D32` green | `check_circle` | `verdictAllowed` | hide | show | show |
| `conditional` | `0xFFF9A825` amber | `verified_user` | `verdictAllowedWithPermission` | hide | show | show |
| `blocked` | `0xFFD32F2F` red | `block` | `verdictNotAllowed` | **show** | show | show |
| `uncertain` | `0xFF607D8B` slate | `help_outline` | `verdictUncertain` ("Verify manually") | hide | show | show (chip reads "uncertain") |

- **Permit CTA** (`howToRequest`) shows for `blocked` only — preserves today's
  `notAllowed` behavior incl. the modality-block fallback in `_permitToHighlight()`.
  It does **not** show for `uncertain` (an uncertain verdict is not "you need a permit").
- **Controlled-airspace banner** gate changes from `verdict != notAllowed` to
  `status != VerdictStatus.blocked`.
- **Reason rendering (no double-render).** `reasons` is the single source of truth,
  but reasons render on exactly one surface each:
  - `mslGroundElevationUnknown` → keeps its **existing dedicated MSL disclaimer
    banner** (now gated by `hasMslAltitudeUncertainty`, which reads `reasons`). No new
    widget, no churn.
  - Every **other** reason (this PR: `zoneDataUnavailable`) → renders in a new
    **reasons section** below the headline (heading `uncertainReasonsHeading`, one
    l10n string per reason). The section excludes reasons that already have a
    dedicated banner, so the MSL message never appears twice.
  - Future axes that add a banner-less reason get a row in this section for free.

### `noZones` under uncertainty (resolves E1/E2)

`noZones` ("General Open Category rules apply…") must **not** render when
`status == uncertain` — printing the cheerful no-zones copy under an "uncertain"
headline is a contradiction. When the repository has no zone data at all
(`zoneDataUnavailable`), the card shows the uncertain headline + reason instead of
`noZones`.

### Out of scope (this PR)

- **Map selection marker stays verdict-agnostic.** The tapped-point marker uses a
  fixed selection color today and does **not** change with the verdict; coloring it
  by `status` is deferred (net-new UX, not required for the model migration).
- **No `uncertain` status from MSL/terrain, GPS buffer, or NOTAM** — those downgrades
  arrive with axes 2–4. This PR emits `uncertain` only for `zoneDataUnavailable`.

### Social snapshot backward/forward compat (resolves B1–B4)

[`create_post_draft.dart`](../../lib/social/create_post_draft.dart) `toVerdictSnapshot()`:

```dart
return {
  ...,
  'verdict': assessment.verdict.name,   // legacy 3-value, for old readers
  'status': assessment.status.name,     // NEW 4-value authority
  'reasons': assessment.reasons.map((r) => r.name).toList(), // NEW
};
```

> **No `schemaVersion`.** The presence of the `status` key *is* the version gate
> (v2 ⇒ `status` present; v1 ⇒ absent). A separate version field would be a second,
> redundant discriminator (YAGNI). A future v3 can add `schemaVersion` and detect v2
> as `status != null && schemaVersion == null`. Record this convention in a code comment.

- **Old app reading new post:** reads `verdict` → safe conservative render (uncertain → notAllowed-style). Graceful, no crash.
- **New app reading new post (v2):** reads `status` (4-value), so a shared `uncertain` post renders as uncertain.
- **New app reading old post (v1, no `status`):** falls back to the `verdict` string.
- **Deserializers** [`post_card.dart`](../../lib/social/view/widgets/post_card.dart)
  and [`reel_feed_item.dart`](../../lib/social/view/widgets/reel_feed_item.dart)
  **prefer `status` when present**, fall back to `verdict` for v1, gain an explicit
  `uncertain` arm, and degrade an unknown string to a **meaningful** neutral
  `socialVerdictUnavailable` render (not the current `socialShareFlyCheck` label,
  which is wrong). Reading only `verdict` would make the `uncertain` arm dead code.

## Technical Considerations

- **Architecture (VGV one-directional layering preserved):** all model + rule
  changes live in `packages/flight_rules_repository`; presentation only reads the
  new `status`/`reasons`. No new package, no dependency-direction change
  (brainstorm Approach A).
- **Compile-time exhaustiveness as a guardrail:** keep all Dart `switch (status)` in
  presentation exhaustive with no `default` arm — adding the next state is then a
  compiler error, not a silent wrong color. The social string switches can't be
  exhaustive, so they get explicit arms + tested neutral fallback.
- **Offline correctness:** `assess()` stays pure and local; `FlightRulesRepository.load`
  already falls back to the bundled snapshot. The only behavioral change offline is
  the **fail-safe upgrade** (empty data → `uncertain`, never false `allowed`).
- **Performance:** negligible — `reasons` is a tiny list built once per `assess()` call.
- **Equatable:** add `status` and `reasons` to `FlightAssessment.props`, and
  **remove `verdict`** from `props` — it is now fully derived from `status`, so
  keeping it is a redundant equality axis.
- **Constructor break:** `verdict` moves from a `required` constructor field to a
  get-only getter; the constructor now takes `required this.status`. Every
  `FlightAssessment(verdict: …)` construction must become `status: …`. Production
  has a single construction site (`assess()`); the rest are tests (see checklist).
- **l10n:** new keys must exist in both `app_en.arb` and `app_es.arb` (Argentine
  *voseo* — "Verificá manualmente"); regenerate `app_localizations*.dart`. No
  hardcoded strings in widgets.

### New l10n keys

| Key | en | es |
|---|---|---|
| `verdictUncertain` | "Verify manually" | "Verificá manualmente" |
| `uncertainReasonsHeading` | "Why we're not sure" | "Por qué no estamos seguros" |
| `reasonZoneDataUnavailable` | "Zone data is unavailable — we can't confirm this point is clear." | "No hay datos de zonas disponibles; no podemos confirmar que el punto esté libre." |
| `socialVerdictUnavailable` | "Verdict unavailable" | "Veredicto no disponible" |

> `mslGroundElevationUnknown` needs **no new key** — it reuses the existing
> `mslGroundElevationDisclaimer` via its dedicated banner, not the reasons section.

## Acceptance Criteria

**Model (`flight_rules_repository`)**

- [ ] `VerdictStatus` and `VerdictReason` (2 values) enums added to `flight_assessment.dart`.
- [ ] `FlightAssessment` carries `status` + `reasons` (no `confidence`); `verdict` is a
      derived compat getter; constructor takes `required this.status`;
      `hasMslAltitudeUncertainty` reads from `reasons`; `props` has `status`/`reasons`
      and **no longer** has `verdict`; `reasons` wrapped `List.unmodifiable`.
- [ ] **Constructor migration:** every `FlightAssessment(verdict: …)` call site moves
      to `status: …` — incl. `flight_assessment_test.dart`,
      `flight_rules_repository_test.dart`, `openaip_assessment_test.dart`, and any
      other construction site (verify by grep that `assess()` is the only production one).
- [ ] `assess()` follows the precedence ladder; dedups `reasons`; existing
      allowed/conditional/blocked outcomes are **unchanged** for non-empty data.
- [ ] Empty repository (`fromZoneData([])`) ⇒ `status == uncertain` +
      `reasons == [zoneDataUnavailable]` (was `allowed`).
- [ ] MSL-limited overlapping zone ⇒ `reasons` contains `mslGroundElevationUnknown`,
      **status not forced to uncertain** (deferred to axis 2).

**Presentation (`zone_detail_card.dart`)**

- [ ] Exhaustive `status` switches (no `default`) for color/icon/headline per the truth table.
- [ ] Permit CTA, controlled-airspace banner, and reasons section behave per the truth table.
- [ ] `noZones` suppressed when `status == uncertain`.

**Social**

- [ ] `toVerdictSnapshot()` emits `status` and `reasons` and keeps `verdict` (no
      `schemaVersion` — `status` presence is the version gate).
- [ ] `post_card.dart` / `reel_feed_item.dart` **prefer `status`** when present, fall
      back to `verdict` for v1, handle `uncertain`, and degrade an unknown string to a
      neutral `socialVerdictUnavailable` render.

**l10n**

- [ ] All new keys in `app_en.arb` + `app_es.arb`; `app_localizations*.dart` regenerated; no hardcoded strings.

**Testing** (VGV: every changed unit covered)

- [ ] `flight_rules_repository` tests: precedence ladder; empty-data → uncertain;
      MSL reason emitted; `reasons` deduped; allowed/conditional/blocked unchanged.
- [ ] `FlightAssessment` getter tests: `verdict` mapping (incl. uncertain → notAllowed),
      `hasMslAltitudeUncertainty` from reasons.
- [ ] **`map_cubit_test` (BLOCKER):** `checkPoint`/`updateZones` on an empty-zone
      repository emit `assessment.status == uncertain` with `reasons` containing
      `zoneDataUnavailable`; existing `assessment.verdict` assertions reviewed/updated.
- [ ] Widget tests: `zone_detail_card` renders all four statuses (color/icon/headline,
      CTA/banner/reasons visibility); `noZones` hidden under uncertain; **controlled-airspace
      banner gate flip** (`status != blocked`) regression-tested — banner shows for
      `uncertain`, hidden for `blocked`.
- [ ] Social tests: v1 snapshot (no `status`) back-compat render unchanged via `verdict`
      fallback; v2 snapshot with `status: uncertain` renders uncertain (proves `status`
      is preferred, arm not dead); `conditional`/`blocked` and a garbage string render
      sanely in `post_card` and `reel_feed_item`.
- [ ] `flutter analyze` clean; `very_good test` green.

## Success Metrics

- Zero `assess()` paths return `allowed` without zone data (verified by test).
- All four `VerdictStatus` values render distinctly on the verdict card.
- Social feed renders old and new snapshots without crash or wrong-label fallback.
- The `reasons[]` channel is in place so axes 2–4 add a reason + a status downgrade
  with **no further consumer migration**.

## Dependencies & Risks

- **Risk — over-flagging uncertainty.** Forcing every MSL zone to `uncertain` before
  DEM exists would erode trust. *Mitigation:* this PR keeps MSL as a reason only; the
  status downgrade is axis 2's job. (Decision recorded above.)
- **Risk — social wire-format break.** *Mitigation:* keep legacy `verdict` string +
  add `status`/`reasons` (presence of `status` is the version gate); deserializers
  prefer `status` with explicit arms + tests for old (v1) and new (v2) payloads.
- **Risk — missed consumer.** *Mitigation:* exhaustive no-`default` switches turn any
  missed presentation site into a compile error; grep inventory below is the migration checklist.
- **Dependency:** none external. Pure refactor of existing domain + presentation.
- **Blocks:** axis 2 (terrain/DEM), axis 3 (geometry/GPS buffer), axis 4 (NOTAM) all
  build on this model.

## Roadmap (subsequent PRs — not in this plan)

| # | Axis | Adds | Emits new reason → status |
|---|---|---|---|
| 2 | Vertical / terrain | offline quantized DEM for Argentina; real `groundElevationMsl`; introduces the `confidence` field (with a consumer) | adds `coarseTerrainData`; MSL-no-terrain → `uncertain` |
| 3 | Horizontal geometry | polygon holes, geodesic PIP, GPS-error buffer, real aerodrome polygons | `nearBoundaryGpsBuffer` → `uncertain` |
| 4 | Temporal / NOTAM | backend NOTAM parse into `/v1/zones`, cached snapshot + staleness | `notamSnapshotStale`, `notamDataUnavailable` → `uncertain` |

## References & Research

**Migration checklist — every verdict consumer (verified by grep):**

- `packages/flight_rules_repository/lib/src/models/flight_assessment.dart` — `FlightVerdict` enum, `FlightAssessment`, getters
- `packages/flight_rules_repository/lib/src/flight_rules_repository.dart:84` — `assess()` verdict assignment
- `lib/map/view/widgets/zone_detail_card.dart:34,45,56,196,232` — exhaustive verdict switches + banners + CTAs
- `lib/map/view/widgets/map_zone_detail_overlay.dart` — passes assessment through (no change expected)
- `lib/map/cubit/map_cubit.dart:76,110` — `assess()` callers
- `lib/social/create_post_draft.dart:21` — snapshot serialization
- `lib/social/view/widgets/post_card.dart:32-34,43` — verdict string deserialization
- `lib/social/view/widgets/reel_feed_item.dart:29-31,42` — verdict string deserialization
- `lib/l10n/arb/app_en.arb` / `lib/l10n/arb/app_es.arb` — verdict + reason strings
- **Test call sites (constructor migration):** `packages/flight_rules_repository/test/flight_assessment_test.dart`,
  `.../test/flight_rules_repository_test.dart`,
  `packages/flight_rules_repository/test/openaip_assessment_test.dart`,
  `lib/map/cubit/map_cubit_test.dart` (under `test/`) — replace `verdict:` with `status:`, update assertions

**Prior art in-repo:** `FlightAssessment.hasMslAltitudeUncertainty` (existing
uncertainty signal driving a banner) is the template the `reasons[]` channel generalizes.

**Source brainstorm:** [2026-06-17-airspace-verdict-accuracy-brainstorm-doc.md](../brainstorm/2026-06-17-airspace-verdict-accuracy-brainstorm-doc.md)
(Approach A, keystone-first sequencing, fail-safe + explicit uncertainty band).

**Flow analysis:** gaps A1–A5, B1–B4, C1–C3, D1–D3, E1–E2, F, G incorporated above.
