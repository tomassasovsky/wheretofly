#!/usr/bin/env python3
"""Regenerate packages/argentina_bounds/lib/argentina_border_path.dart from Natural Earth."""

from __future__ import annotations

import json
import ssl
import urllib.request
from pathlib import Path

# Natural Earth 10m admin-0 — high precision (~8k+ vertices for Argentina).
SOURCE_URL = (
    "https://raw.githubusercontent.com/nvkelso/natural-earth-vector/"
    "master/geojson/ne_10m_admin_0_countries.geojson"
)
ADM0_A3 = "ARG"
OUT = (
    Path(__file__).resolve().parents[2]
    / "packages/argentina_bounds/lib/argentina_border_path.dart"
)


def fetch_geojson() -> dict:
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    with urllib.request.urlopen(SOURCE_URL, context=ctx, timeout=60) as resp:
        return json.load(resp)


def extract_rings(feature: dict) -> list[list[tuple[float, float]]]:
    geometry = feature["geometry"]
    gtype = geometry["type"]
    polys: list[list[list[list[float]]]] = []
    if gtype == "Polygon":
        polys = [geometry["coordinates"]]
    elif gtype == "MultiPolygon":
        polys = geometry["coordinates"]
    else:
        raise ValueError(f"Unsupported geometry type: {gtype}")

    rings: list[list[tuple[float, float]]] = []
    for poly in polys:
        outer = poly[0]
        rings.append([(pt[1], pt[0]) for pt in outer])  # (lat, lon)
    return rings


def emit_dart(rings: list[list[tuple[float, float]]]) -> str:
    total = sum(len(r) for r in rings)
    lines = [
        "// Argentina ADM0 outline (Natural Earth 10m).",
        "// GeoJSON [lon, lat] stored as (lat, lon) for ray casting.",
        f"// {len(rings)} polygons, {total} vertices total.",
        "// Regenerate: python3 tooling/argentina_bounds/regenerate_border_path.py",
        "abstract final class ArgentinaBorderPath {",
        "  ArgentinaBorderPath._();",
        "",
        f"  static const polygonCount = {len(rings)};",
        "",
    ]
    for i, ring in enumerate(rings):
        lines.append(f"  /// Polygon {i}: {len(ring)} vertices.")
        lines.append(f"  static const ring{i} = <(double lat, double lon)>[")
        for lat, lon in ring:
            lines.append(f"    ({lat}, {lon}),")
        lines.append("  ];")
        lines.append("")
    ring_names = ", ".join(f"ring{i}" for i in range(len(rings)))
    lines.append(f"  static const allRings = [{ring_names}];")
    lines.append("}")
    lines.append("")
    return "\n".join(lines)


def main() -> None:
    data = fetch_geojson()
    feature = next(
        f for f in data["features"] if f["properties"].get("ADM0_A3") == ADM0_A3
    )
    rings = extract_rings(feature)
    OUT.write_text(emit_dart(rings), encoding="utf-8")
    print(f"Wrote {OUT} ({len(rings)} polygons, {sum(len(r) for r in rings)} vertices)")


if __name__ == "__main__":
    main()
