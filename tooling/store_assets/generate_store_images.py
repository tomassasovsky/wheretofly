#!/usr/bin/env python3
"""Compose raw app screenshots into store-ready marketing images (phone mockups).

Reads PNGs from docs/screenshots/ and writes framed assets under store/.
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFont

REPO_ROOT = Path(__file__).resolve().parents[2]
ASSETS_DIR = Path(__file__).resolve().parent
FRAME_IPHONE = ASSETS_DIR / "device-frames" / "iphone-16-pro-max-black-titanium"
FRAME_ANDROID = ASSETS_DIR / "device-frames" / "pixel-9-pro-obsidian"
FRAME_PIXEL_TABLET = ASSETS_DIR / "device-frames" / "pixel-tablet-hazel"
TABLET_SIZE_NAMES = frozenset({"android_tablet_7", "android_tablet_10"})
RAW_DIRS: dict[str, Path] = {
    "en": REPO_ROOT / "docs" / "screenshots" / "en",
    "es": REPO_ROOT / "docs" / "screenshots" / "es",
}
STORE_DIR = REPO_ROOT / "store"

# Render marketing frames at 2× then downsample for sharper type and screenshots.
_RENDER_SCALE = 2

# Matches AppTheme (violet light mode).
BRAND = (0x4A, 0x1A, 0x8F)
ACCENT = (0x6D, 0x28, 0xD9)
BG_TOP = (0xFF, 0xFF, 0xFF)
BG_BOTTOM = BRAND
TITLE_COLOR = BRAND
SUBTITLE_COLOR = (0x6B, 0x60, 0x80)


@dataclass(frozen=True)
class Slide:
    raw_name: str
    headline: str
    subheadline: str
    output_name: str


SLIDES_EN: tuple[Slide, ...] = (
    Slide(
        "01-map-zones",
        "Know where you can fly",
        "Restriction zones across Argentina on an interactive map",
        "01-map-zones",
    ),
    Slide(
        "02-map-verdict",
        "Instant flight verdicts",
        "Tap anywhere — see if you may fly with your permission and modality",
        "02-map-verdict",
    ),
    Slide(
        "03-config-sheet",
        "Your permission & modality",
        "VLOS, BVLOS, night, altitude — matched to ANAC rules",
        "03-config-sheet",
    ),
    Slide(
        "04-map-search",
        "Search anywhere in Argentina",
        "Geocoded places with offline-friendly lookups",
        "04-map-search",
    ),
    Slide(
        "05-resources",
        "Official permit guidance",
        "Step-by-step links to ANAC and government resources",
        "05-resources",
    ),
    Slide(
        "06-map-wind",
        "Wind gust overlay",
        "Open-Meteo gust field to plan safer flights",
        "06-map-wind",
    ),
)

SLIDES_ES: tuple[Slide, ...] = tuple(
    Slide(
        s.raw_name,
        {
            "01-map-zones": "Sabé dónde podés volar",
            "02-map-verdict": "Veredictos al instante",
            "03-config-sheet": "Tu permiso y modalidad",
            "04-map-search": "Buscá en toda Argentina",
            "05-resources": "Guía oficial de permisos",
            "06-map-wind": "Capa de ráfagas de viento",
        }[s.raw_name],
        {
            "01-map-zones": "Zonas de restricción en un mapa interactivo",
            "02-map-verdict": "Tocá el mapa y mirá si podés volar con tu permiso",
            "03-config-sheet": "VLOS, BVLOS, noche, altitud — según normas ANAC",
            "04-map-search": "Lugares geocodificados, con caché para uso offline",
            "05-resources": "Enlaces a ANAC y trámites del Estado",
            "06-map-wind": "Campo de ráfagas Open-Meteo para planificar mejor",
        }[s.raw_name],
        s.output_name,
    )
    for s in SLIDES_EN
)

CANVAS_SIZES: dict[str, tuple[int, int]] = {
    "ios_6.7": (1290, 2796),
    "ios_6.5": (1284, 2778),
    "ios_6.1": (1179, 2556),
    "android_phone": (1080, 1920),
    # Play Console 7-inch tablet — 9:16 portrait (recommended 1200×1920).
    "android_tablet_7": (1200, 1920),
    # Play Console 10-inch tablet — 9:16 portrait (min 1080 short side; 1600×2560).
    "android_tablet_10": (1600, 2560),
}


@dataclass(frozen=True)
class DeviceFrameSet:
    frame: Image.Image
    mask: Image.Image
    screen_x: int
    screen_y: int
    screen_w: int
    screen_h: int
    frame_w: int
    frame_h: int


_FRAME_CACHE: dict[Path, DeviceFrameSet] = {}


def _frame_dir_for_size(size_name: str) -> Path:
    if size_name in TABLET_SIZE_NAMES:
        return FRAME_PIXEL_TABLET
    if size_name.startswith("android_"):
        return FRAME_ANDROID
    return FRAME_IPHONE


def _rotate_frame_set_cw(src: DeviceFrameSet) -> DeviceFrameSet:
    """Return a copy of [src] rotated 90° clockwise (landscape → portrait)."""
    frame = src.frame.rotate(-90, expand=True)
    mask = src.mask.rotate(-90, expand=True)
    # After 90° CW in a frame of size (W, H):
    #   new frame size  = (H, W)
    #   screen rect transforms as:
    #     new_x = H - old_y - old_h
    #     new_y = old_x
    #     new_w = old_h   (dimensions swap)
    #     new_h = old_w
    return DeviceFrameSet(
        frame=frame,
        mask=mask,
        screen_x=src.frame_h - src.screen_y - src.screen_h,
        screen_y=src.screen_x,
        screen_w=src.screen_h,
        screen_h=src.screen_w,
        frame_w=src.frame_h,
        frame_h=src.frame_w,
    )


def _raw_dir_for(locale: str, size_name: str) -> Path:
    base = RAW_DIRS[locale]
    if size_name in TABLET_SIZE_NAMES:
        return base / size_name
    return base


def _require_frames(frame_dir: Path) -> None:
    missing = [frame_dir / name for name in ("frame.png", "mask.png", "template.json") if not (frame_dir / name).exists()]
    if missing:
        lines = "\n".join(f"  - {p}" for p in missing)
        raise SystemExit(
            f"Device frames not found:\n{lines}\nRun: ./tooling/store_assets/download_device_frames.sh"
        )


def _load_device_frame_set(frame_dir: Path) -> DeviceFrameSet:
    if frame_dir in _FRAME_CACHE:
        return _FRAME_CACHE[frame_dir]
    _require_frames(frame_dir)
    template = json.loads((frame_dir / "template.json").read_text(encoding="utf-8"))
    screen = template["screen"]
    size = template["frameSize"]
    loaded = DeviceFrameSet(
        frame=Image.open(frame_dir / "frame.png").convert("RGBA"),
        mask=Image.open(frame_dir / "mask.png").convert("L"),
        screen_x=screen["x"],
        screen_y=screen["y"],
        screen_w=screen["width"],
        screen_h=screen["height"],
        frame_w=size["width"],
        frame_h=size["height"],
    )
    _FRAME_CACHE[frame_dir] = loaded
    return loaded


def _phone_outer_size_for_frame(
    frame_w: int,
    frame_h: int,
    max_outer_w: int,
    max_outer_h: int,
) -> tuple[int, int]:
    scale = min(max_outer_w / frame_w, max_outer_h / frame_h)
    return round(frame_w * scale), round(frame_h * scale)


def _load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Supplemental/SF-Pro-Display-Bold.otf",
        "/System/Library/Fonts/Supplemental/SF-Pro-Display-Regular.otf",
        "/Library/Fonts/Arial Bold.ttf" if bold else "/Library/Fonts/Arial.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
        if bold
        else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for path in candidates:
        p = Path(path)
        if p.exists():
            try:
                return ImageFont.truetype(str(p), size)
            except OSError:
                continue
    return ImageFont.load_default()


def _aspect_ratio(size: tuple[int, int]) -> float:
    w, h = size
    return w / max(h, 1)


def _fit_uniform(
    src_size: tuple[int, int],
    max_size: tuple[int, int],
) -> tuple[int, int]:
    sw, sh = src_size
    max_w, max_h = max_size
    scale = min(max_w / sw, max_h / sh)
    return round(sw * scale), round(sh * scale)


def _letterbox_to_canvas(
    image: Image.Image,
    canvas_size: tuple[int, int],
) -> Image.Image:
    """Scale uniformly to fit inside canvas_size; pad with the marketing gradient."""
    tw, th = canvas_size
    nw, nh = _fit_uniform(image.size, canvas_size)
    resized = image.convert("RGBA").resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = _vertical_gradient(canvas_size).convert("RGBA")
    canvas.paste(resized, ((tw - nw) // 2, (th - nh) // 2), resized)
    return canvas.convert("RGB")


def _vertical_gradient(size: tuple[int, int]) -> Image.Image:
    w, h = size
    img = Image.new("RGB", size)
    draw = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(h - 1, 1)
        # Ease through brand tones.
        r = int(BG_TOP[0] * (1 - t) + BG_BOTTOM[0] * t)
        g = int(BG_TOP[1] * (1 - t) + BG_BOTTOM[1] * t)
        b = int(BG_TOP[2] * (1 - t) + BG_BOTTOM[2] * t)
        draw.line([(0, y), (w, y)], fill=(r, g, b))
    return img


def _wrap_text(
    draw: ImageDraw.ImageDraw,
    text: str,
    font: ImageFont.FreeTypeFont | ImageFont.ImageFont,
    max_width: int,
) -> list[str]:
    words = text.split()
    lines: list[str] = []
    current: list[str] = []
    for word in words:
        trial = " ".join(current + [word])
        bbox = draw.textbbox((0, 0), trial, font=font)
        if bbox[2] - bbox[0] <= max_width:
            current.append(word)
        else:
            if current:
                lines.append(" ".join(current))
            current = [word]
    if current:
        lines.append(" ".join(current))
    return lines or [text]


def _draw_headline_block(
    canvas: Image.Image,
    slide: Slide,
    *,
    margin: int | None = None,
) -> int:
    draw = ImageDraw.Draw(canvas)
    w, _ = canvas.size
    margin = margin if margin is not None else round(w * 0.074)
    max_text_w = w - margin * 2

    title_font = _load_font(int(w * 0.058), bold=True)
    sub_font = _load_font(int(w * 0.028))

    y = int(canvas.size[1] * 0.09)
    for line in _wrap_text(draw, slide.headline, title_font, max_text_w):
        draw.text((margin, y), line, fill=TITLE_COLOR, font=title_font)
        bbox = draw.textbbox((margin, y), line, font=title_font)
        y = bbox[3] + 8

    y += 12
    bar_w = int(w * 0.14)
    draw.rounded_rectangle(
        (margin, y, margin + bar_w, y + 6),
        radius=3,
        fill=(*ACCENT,),
    )
    y += 28

    for line in _wrap_text(draw, slide.subheadline, sub_font, max_text_w):
        draw.text((margin, y), line, fill=SUBTITLE_COLOR, font=sub_font)
        bbox = draw.textbbox((margin, y), line, font=sub_font)
        y = bbox[3] + 6

    return y


def _device_frame(
    screenshot: Image.Image,
    devices: DeviceFrameSet,
    *,
    outer_w: int,
    outer_h: int,
) -> Image.Image:
    """Place [screenshot] in a PNG device frame (device-frames-media)."""
    scale = min(outer_w / devices.frame_w, outer_h / devices.frame_h)
    fw = round(devices.frame_w * scale)
    fh = round(devices.frame_h * scale)

    frame = devices.frame.resize((fw, fh), Image.Resampling.LANCZOS)
    mask = devices.mask.resize((fw, fh), Image.Resampling.LANCZOS)

    sx = round(devices.screen_x * scale)
    sy = round(devices.screen_y * scale)
    sw = round(devices.screen_w * scale)
    sh = round(devices.screen_h * scale)

    shot = screenshot.convert("RGBA").resize((sw, sh), Image.Resampling.LANCZOS)

    screen_layer = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
    screen_layer.paste(shot, (sx, sy))
    r, g, b, a = screen_layer.split()
    a = ImageChops.multiply(a, mask)
    screen_layer = Image.merge("RGBA", (r, g, b, a))

    out = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
    out.alpha_composite(screen_layer)
    out.alpha_composite(frame)
    return out


def _compose_slide(
    screenshot: Image.Image,
    slide: Slide,
    canvas_size: tuple[int, int],
    *,
    devices: DeviceFrameSet,
) -> Image.Image:
    scale = _RENDER_SCALE
    cw, ch = canvas_size
    render_size = (cw * scale, ch * scale)

    canvas = _vertical_gradient(render_size).convert("RGBA")
    headline_bottom = _draw_headline_block(canvas, slide)

    w, h = render_size
    max_phone_w = int(w * 0.92)
    max_phone_h = h - headline_bottom - int(h * 0.03)
    phone_w, phone_h = _phone_outer_size_for_frame(
        devices.frame_w,
        devices.frame_h,
        max_phone_w,
        max_phone_h,
    )
    phone = _device_frame(
        screenshot,
        devices,
        outer_w=phone_w,
        outer_h=phone_h,
    )

    px = (w - phone.width) // 2
    py = max(headline_bottom + int(h * 0.03), int(h * 0.28))
    canvas.alpha_composite(phone, (px, py))

    return canvas.resize(canvas_size, Image.Resampling.LANCZOS).convert("RGB")



def _compose_slide_tablet(
    screenshot: Image.Image,
    slide: Slide,
    canvas_size: tuple[int, int],
    *,
    devices: DeviceFrameSet,
) -> Image.Image:
    """Tablet store slide: same composition as phone but with a tablet frame."""
    return _compose_slide(screenshot, slide, canvas_size, devices=devices)


def _feature_graphic(
    slides: tuple[Slide, ...],
    raw_dir: Path,
    *,
    locale: str,
) -> Image.Image:
    """Google Play feature graphic 1024×500."""
    w, h = 1024, 500
    base = _vertical_gradient((w, h))
    draw = ImageDraw.Draw(base)
    title_font = _load_font(52, bold=True)
    sub_font = _load_font(22)
    title = "Dónde Vuelo" if locale == "es" else "Where To Fly"
    draw.text((48, 72), title, fill=TITLE_COLOR, font=title_font)
    subtitle = (
        "Reglas de vuelo con drones en Argentina"
        if locale == "es"
        else "Drone flight rules across Argentina"
    )
    draw.text(
        (48, 140),
        subtitle,
        fill=SUBTITLE_COLOR,
        font=sub_font,
    )
    draw.rounded_rectangle((48, 188, 200, 196), radius=3, fill=ACCENT)

    hero = _resolve_raw(raw_dir, slides[0].raw_name)
    if hero is not None:
        devices = _load_device_frame_set(FRAME_IPHONE)
        shot = Image.open(hero)
        pw, ph = _phone_outer_size_for_frame(
            devices.frame_w,
            devices.frame_h,
            max_outer_w=320,
            max_outer_h=440,
        )
        phone = _device_frame(shot, devices, outer_w=pw, outer_h=ph)
        base.paste(phone, (w - pw - 40, (h - ph) // 2), phone)
    return base


def _export_raw_bucket(
    raw_dir: Path,
    out_dir: Path,
    target: tuple[int, int],
) -> None:
    if not raw_dir.is_dir():
        return
    out_dir.mkdir(parents=True, exist_ok=True)
    target_ratio = _aspect_ratio(target)
    for path in sorted(raw_dir.glob("*.png")):
        img = Image.open(path)
        src_ratio = _aspect_ratio(img.size)
        if abs(src_ratio - target_ratio) > 0.02:
            print(
                f"warn {path.name}: capture aspect {src_ratio:.3f} != "
                f"export {target_ratio:.3f} — letterboxing (re-capture at {target[0]}×{target[1]})"
            )
        _letterbox_to_canvas(img, target).save(
            out_dir / path.name,
            optimize=True,
        )


def _export_raw_screenshots(locale: str, store_dir: Path) -> None:
    """Copy raw captures sized for direct store upload."""
    base = RAW_DIRS[locale]
    shots = store_dir / "screenshots" / locale
    _export_raw_bucket(base, shots / "ios_6.7_raw", (1290, 2796))
    _export_raw_bucket(base, shots / "android_phone_raw", (1080, 1920))
    _export_raw_bucket(base / "android_tablet_7", shots / "android_tablet_7_raw", (1200, 1920))
    _export_raw_bucket(base / "android_tablet_10", shots / "android_tablet_10_raw", (1600, 2560))


# Legacy captures from wind_map_screenshot_test.dart
_RAW_ALIASES: dict[str, str] = {
    "06-map-wind": "02-map-wind",
}


def _resolve_raw(raw_dir: Path, raw_name: str) -> Path | None:
    direct = raw_dir / f"{raw_name}.png"
    if direct.exists():
        return direct
    alias = _RAW_ALIASES.get(raw_name)
    if alias:
        aliased = raw_dir / f"{alias}.png"
        if aliased.exists():
            return aliased
    return None


def generate(
    *,
    raw_dir: Path,
    store_dir: Path,
    slides: tuple[Slide, ...],
    locale: str,
) -> None:
    store_dir.mkdir(parents=True, exist_ok=True)

    phone_raw = raw_dir
    for size_name, canvas_size in CANVAS_SIZES.items():
        size_raw = _raw_dir_for(locale, size_name)
        out_dir = store_dir / "marketing" / locale / size_name
        out_dir.mkdir(parents=True, exist_ok=True)
        for slide in slides:
            raw_path = _resolve_raw(size_raw, slide.raw_name)
            if raw_path is None:
                print(f"skip missing {size_raw / slide.raw_name}.png")
                continue
            shot = Image.open(raw_path)
            canvas_ratio = _aspect_ratio(canvas_size)
            shot_ratio = _aspect_ratio(shot.size)
            if size_name in TABLET_SIZE_NAMES and abs(shot_ratio - canvas_ratio) > 0.02:
                print(
                    f"warn {raw_path}: {shot.size[0]}×{shot.size[1]} aspect {shot_ratio:.3f} "
                    f"≠ canvas {canvas_size[0]}×{canvas_size[1]} ({canvas_ratio:.3f}); "
                    "re-run capture_android_tablets.sh for matching tablet UI"
                )
            devices = _load_device_frame_set(_frame_dir_for_size(size_name))
            if size_name in TABLET_SIZE_NAMES:
                # The Pixel Tablet frame is landscape; rotate it to portrait
                # to match the portrait screenshots captured by the emulator.
                devices = _rotate_frame_set_cw(devices)
                composed = _compose_slide_tablet(
                    shot, slide, canvas_size, devices=devices
                )
            else:
                composed = _compose_slide(shot, slide, canvas_size, devices=devices)
            out_path = out_dir / f"{slide.output_name}.png"
            composed.save(out_path, optimize=True, compress_level=3)
            print(f"wrote {out_path}")

    fg_dir = store_dir / "play"
    fg_dir.mkdir(parents=True, exist_ok=True)
    fg_path = fg_dir / f"feature_graphic_{locale}.png"
    _feature_graphic(slides, phone_raw, locale=locale).save(
        fg_path,
        optimize=True,
        compress_level=3,
    )
    print(f"wrote {fg_path}")

    _export_raw_screenshots(locale, store_dir)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--raw-dir",
        type=Path,
        default=None,
        help="Directory with 01-map-zones.png (default: docs/screenshots/<locale>)",
    )
    parser.add_argument(
        "--store-dir",
        type=Path,
        default=STORE_DIR,
        help="Output root (default: store/)",
    )
    parser.add_argument(
        "--locale",
        choices=("en", "es", "all"),
        default="all",
    )
    args = parser.parse_args()

    if args.locale in ("en", "all"):
        generate(
            raw_dir=args.raw_dir or RAW_DIRS["en"],
            store_dir=args.store_dir,
            slides=SLIDES_EN,
            locale="en",
        )
    if args.locale in ("es", "all"):
        generate(
            raw_dir=args.raw_dir or RAW_DIRS["es"],
            store_dir=args.store_dir,
            slides=SLIDES_ES,
            locale="es",
        )


if __name__ == "__main__":
    main()
