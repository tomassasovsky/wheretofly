---
date: 2026-06-18
topic: zone-completeness-accuracy
---

# Complete, Authoritative Airspace Zone Coverage

## What We're Building

A program to make the app's zone data **complete and authoritatively sourced**:
every published controlled/restricted airspace zone that affects drone/RPAS
flight in Argentina should appear in the app, sourced from canonical authorities
rather than approximations. Today the feed has ~694 zones, but only 12 are exact
AIP polygons (TMA BAIRES + 10 CTRs + 1 SAR); the rest are MADHEL aerodrome
circles, bundled sites, and OpenAIP community polygons. The **Prohibited (P),
Restricted (R), and Danger (D) areas defined in ANAC AIP ENR 5.1 are largely
absent** — that is the central gap.

This effort is about **data completeness and source authority**, distinct from
the sibling `2026-06-17-airspace-verdict-accuracy` brainstorm, which is about how
the verdict *reasons* over zones (terrain, geometry, GPS, confidence). This
effort owns getting all the right zones into the `/v1/zones` feed from the right
sources; that effort owns what the verdict does with them.

## Why This Approach

The activity is **drones/RPAS**, so the relevant restrictions are genuine
**published airspace zones** — controlled airspace (CTR/TMA), and P/R/D areas.
Fuzzy contextual rules (no flight over groups of people, urban agglomeration
limits) are explicitly **out of scope as map zones** — they can't be faithfully
drawn and will be handled, if at all, as verdict text, not geometry.

Three sourcing strategies were weighed:

- **A — Curated AIP parser for everything.** Transcribe every ENR 5 zone into the
  hardcoded `zone_database.dart` and parse with the existing
  `BoundaryParser`/`ArcDensifier`. Maximum authority, but redoes work OpenAIP
  already does well and carries a heavy per-AIRAC transcription burden.
- **B — Fully automated AIXM/PDF extraction.** Best only if EANA/ANAC publishes a
  structured AIXM 5.1 source; brittle if only PDF exists.
- **C — OpenAIP-primary.** Fast breadth, but community data is not legally
  canonical on its own.

**Chosen: a gap-filling hybrid (C-breadth + A-fill).** OpenAIP's polygons are
treated as the reliable **geometry baseline** for the zones it already covers
(its AR airspace footprints are good). ANAC AIP ENR 5 is treated as the
**authoritative inventory** — the complete list of zones that *must* exist. We
diff the AIP inventory against OpenAIP coverage to find what is **missing**, and
fill only those gaps via the curated parser (Approach A). The existing
`validate_openaip_zones.dart` tool cross-checks geometry agreement and flags
large discrepancies for manual review. This honors "true, accurate sources"
without re-transcribing zones OpenAIP already represents faithfully.

## Key Decisions

- **Activity = drones/RPAS.** Defines "zones with air restrictions" as published
  controlled and restricted airspace, not contextual behavioral rules.
- **Only real published airspace is drawn.** No synthetic urban/crowd/proximity
  geometry. Rules that can't be faithfully mapped are not invented as zones.
- **AIP is the inventory; OpenAIP is the geometry baseline.** AIP ENR 5 defines
  *which* zones must exist (authority over existence/completeness); OpenAIP
  provides the polygon *where it has one*; AIP-parsed geometry fills gaps. On
  large geometry conflict, AIP wins and the discrepancy is logged for review.
- **OpenAIP demoted from "just another source" to validated breadth.** It stays
  in the merge, but its coverage is now audited against a canonical inventory
  rather than trusted blindly.
- **Core new deliverable = a coverage gap analysis.** Build/obtain the canonical
  ENR 5 P/R/D inventory, diff against the live feed, and produce a concrete
  list of missing zones to transcribe — not a blind re-transcription.
- **NOTAMs/temporal in scope, as a separate backend ingestion layer.** This
  effort owns getting time-bounded restrictions into the feed from an
  authoritative Argentine NOTAM source; the verdict-accuracy brainstorm owns how
  staleness/confidence affects the resulting verdict. Clean data/logic split.
- **Offline-first preserved.** New static zones bundle into the published
  GeoJSON exactly like today's AIP zones; NOTAM snapshots cache client-side with
  a sync timestamp.

## Research Findings (spikes, 2026-06-18)

Three research spikes resolved most open questions:

- **No structured AIP exists, but ENR 5 PDFs are real text PDFs.** ANAC/EANA
  publish no AIXM 5.1, no eAIP (HTML/XML), no GML, and no airspace-geometry
  dataset — only PDF at `https://ais.anac.gob.ar`. The ANAC open-data file
  `a1-2_datos_sobre_espacio_aereo.xlsx` is an empty PANS-AIM *template*, not
  data. **However**, the ENR 5 PDFs are text-based (not scanned), so
  `pdftotext -layout` extracts designators and DMS coordinates cleanly →
  **the gap-fill is semi-automatable parsing, not hand-keying.** This rules out
  Approach B (no machine-readable source) but makes Approach A far cheaper than
  feared.
- **ENR 5.1 inventory is concrete: 85 zones** — 18 Prohibited (`SAP`), 66
  Restricted (`SAR`), 1 Danger (`SAD 60`). Designators use the `SA` prefix with
  a shared, non-contiguous number series (e.g. `SAP 03`, `SAR 105`). ENR 5
  subsection map confirmed: 5.0 generalities, **5.1 P/R/D**, 5.2 military/ADIZ,
  5.3 other hazards, 5.4 obstacles, **5.5 sporting/recreational**, 5.6 bird/fauna.
- **Drone-relevant AIP sections:** ENR 5.1 (P/R/D) + ENR 5.5 (glider/recreational
  sectors) + ENR 2.1 (TMA/FIR/CTA) + per-aerodrome AD 2.17 (CTRs). The current
  parser already covers the last two for a handful of aerodromes; ENR 5.1/5.5 are
  the gap.
- **Current regulatory framework is Res. ANAC 550/2025** (RAAC Parte 100/101/102,
  built on Decreto 663/2024), modified by Res. 311–313/2026 — **not** the
  2019–2020 resolutions the codebase/docs currently reference. No official ANAC
  drone no-fly map or dataset exists, confirming AIP synthesis is the only path.
- **Vertical limits are decisive for drones.** Many ENR 5.1 zones are based at
  flight levels that never constrain a sub-122 m (or 43 m near-aerodrome) drone.
  The verdict must filter zones by altitude overlap (the altitude model already
  supports this) so we don't show irrelevant high-altitude restrictions as
  blocking.
- **NOTAMs: a confirmed free, no-auth, CORS-open endpoint exists.**
  `POST https://ais.anac.gob.ar/notam/pib` with body `indicador=<code>` returns an
  HTML table where EANA has **pre-extracted `Desde:`/`Hasta:` validity windows**
  plus ICAO free-text bodies carrying `COORD GEO <DMS>...` (+ optional `RDO <n>NM`)
  geometry and `F)/G)` vertical limits. FIR codes are EANA-internal:
  `-EF` Ezeiza, `-CF` Córdoba, `-VF` Comodoro, `-MF` Mendoza, `-RR` Resistencia.
  Many entries are exactly the temporary zones wanted (drone ops, parachuting,
  gunnery exercises). Drawable geometry is extractable with a tolerant regex
  parser + a "could-not-geocode → flag for manual review" fallback. No licensing
  published — treat as a scrape, attribute, and never present as an official PIB.

## Open Questions (remaining for planning)

- **Coverage diff method.** How to match an AIP zone to an OpenAIP zone for
  "covered vs missing" — by designator (`SAR…`/`SAP…`), spatial overlap, or both?
  Designators likely differ between sources; spatial overlap may be more robust.
- **Discrepancy threshold.** What geometry delta (centroid offset, area ratio,
  Hausdorff distance) between AIP and OpenAIP triggers "AIP wins, flag for review"
  vs "accept OpenAIP"?
- **AIRAC maintenance.** How to keep the parsed set in sync each 28-day cycle —
  re-scrape `/aip/enr` (hashes change per amendment) and diff, with a review
  checklist. Worth a lightweight automated diff alert.
- **National parks.** APN protected areas restrict drones but aren't AIP airspace
  — keep current circular approximations, upgrade to real boundaries, or treat as
  a separate authoritative layer? Borderline with "only published airspace."
- **Aerodrome proximity buffers (5 km / 43 m AGL).** A real RAAC 101 constraint
  and drawable, but the "only published airspace" decision leans against
  synthesizing it as geometry. Decide: draw as a distinct buffer layer, or surface
  as verdict text only?
- **Provenance in the feed.** Add a `source`/`authority` field per zone (AIP /
  OpenAIP / NOTAM / MADHEL) so UI and validation can reason about trust and
  staleness — almost certainly yes; confirm during planning.
- **Stale-doc cleanup.** Update codebase/doc references from the 2019–2020
  resolutions to Res. 550/2025 + 311–313/2026.
