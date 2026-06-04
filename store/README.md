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

Uses `iPhone 16 Pro Max` for phone/iOS assets. **Android tablets** use the **same** `integration_test/store_screenshot_test.dart` as phone — only the emulator and `wm size` differ.

```bash
# Phone/iOS only (skip tablet emulators)
STORE_CAPTURE_TABLETS=no ./tooling/store_assets/capture_and_generate.sh

# Tablets only (after creating AVDs — see below)
./tooling/store_assets/capture_android_tablets.sh
source tooling/store_assets/_ensure_pillow.sh && ensure_pillow
"$STORE_ASSETS_PYTHON" tooling/store_assets/generate_store_images.py --locale all
```

### Android tablet AVDs

| Bucket | Play size | AVD | `wm size` |
|--------|-----------|-----|-----------|
| `android_tablet_7` | 1200×1920 | `Tablet_7_API_35` (Nexus 7) | 1200×1920 |
| `android_tablet_10` | 1600×2560 | `Pixel_Tablet_API_36` | 1600×2560 |

Wind overlay capture needs network (Open-Meteo tiles).

## App icon (store upload)

Source artwork: `assets/icon/app_icon.png` (1024×1024). Regenerate platform icons with `dart run flutter_launcher_icons`.

| Path | Use |
|------|-----|
| `icon/app-icon-512.png` | **Google Play** — high-res icon (512×512) |
| `icon/app-icon-1024-no-alpha.png` | **App Store** — app icon (1024×1024, no transparency) |
| `icon/app-icon-1024.png` | Master PNG with alpha (same as source) |

## What you get

| Path | Use |
|------|-----|
| `marketing/en/ios_6.7/` | App Store — English, 1290×2796 |
| `marketing/es/ios_6.7/` | App Store — Spanish UI + copy |
| `marketing/*/android_phone/` | Play Store — phone, 1080×1920 |
| `marketing/*/android_tablet_7/` | Play Store — **7-inch tablet**, 1200×1920 |
| `marketing/*/android_tablet_10/` | Play Store — **10-inch tablet**, 1600×2560 |
| `docs/screenshots/<locale>/android_tablet_7/` | Raw 7-inch tablet emulator PNGs |
| `docs/screenshots/<locale>/android_tablet_10/` | Raw 10-inch tablet emulator PNGs |
| `play/feature_graphic_en.png` / `_es.png` | Play feature graphic — 1024×500 |

For current large iPhones, **`ios_6.7`** is the primary upload set.

## Manual capture (same test as phone)

```bash
export STORE_SCREENSHOT_DIR="$(pwd)/docs/screenshots/en/android_tablet_10"
adb -s emulator-5554 shell wm size 1600x2560
adb -s emulator-5554 shell wm density 320

flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/store_screenshot_test.dart \
  -d emulator-5554 \
  --dart-define=STORE_SCREENSHOT_LOCALE=en
```

## Source screenshots

The integration test records six screens per locale: zones map, verdict, config sheet, search, resources, wind overlay.

Brand colours match `AppTheme` (`#3B0297` indigo).
