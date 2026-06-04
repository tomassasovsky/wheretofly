# Store listing assets

Professional **app-on-phone** marketing images built from **real simulator screenshots** of Dónde Volar.

## Quick start

```bash
chmod +x tooling/store_assets/capture_and_generate.sh
./tooling/store_assets/capture_and_generate.sh
```

Captures **twice** (English + Spanish UI) via `flutter drive` in **light theme**, then composes at **2× resolution** and downsamples to store sizes for sharper output.

Phone mockups use PNG frames from [device-frames-media](https://github.com/jonnyjackson26/device-frames-media) (iPhone 16 Pro Max + Pixel 9 Pro). See `store/ATTRIBUTION.md`. First-time setup:

```bash
chmod +x tooling/store_assets/download_device_frames.sh
./tooling/store_assets/download_device_frames.sh
```

- Raw EN: `docs/screenshots/en/`
- Raw ES: `docs/screenshots/es/`
- Marketing copy: Spanish headlines **and** Spanish in-app screenshots for `marketing/es/`

Uses `iPhone 16 Pro Max` by default. Override:

```bash
STORE_SCREENSHOT_DEVICE="iPhone 16 Pro" ./tooling/store_assets/capture_and_generate.sh
```

Wind overlay capture needs network (Open-Meteo tiles) or a local tile server on iOS debug (`tooling/om_tile_server`).

## What you get

| Path | Use |
|------|-----|
| `marketing/en/ios_6.7/` | App Store — English, 1290×2796 |
| `marketing/es/ios_6.7/` | App Store — Spanish UI + copy |
| `marketing/*/android_phone/` | Play Store — 1080×1920 |
| `play/feature_graphic_en.png` / `_es.png` | Play feature graphic — 1024×500 |
| `screenshots/<locale>/ios_6.7_raw/` | Unframed uploads (optional) |

For current large iPhones, **`ios_6.7`** is the primary upload set.

## Manual steps

```bash
# Capture one locale
STORE_SCREENSHOT_DIR="$(pwd)/docs/screenshots/es" \
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/store_screenshot_test.dart \
  -d "iPhone 16 Pro Max" \
  --dart-define=STORE_SCREENSHOT_AUTO_SELECT=true \
  --dart-define=STORE_SCREENSHOT_LOCALE=es

python3 tooling/store_assets/generate_store_images.py --locale all
```

## Source screenshots

The integration test records six screens per locale: zones map, verdict, config sheet, search, resources, wind overlay.

Brand colours match `AppTheme` (`#3B0297` indigo).
