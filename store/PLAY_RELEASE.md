# Google Play — first release (v1.0.0)

## Build artifact

| Field | Value |
|-------|--------|
| Version | `1.0.0` (`versionCode` **1**) from `pubspec.yaml` |
| Package | `dev.aquiles.wheretofly` |
| Format | Android App Bundle (required for new apps) |
| Output | `build/app/outputs/bundle/release/app-release.aab` |

## Build (signed release)

Signing uses `android/key.properties` and `android/app/upload-keystore.jks`
(see `scripts/setup_android_signing.sh`).

```bash
flutter build appbundle --release
```

Optional APK for sideload/testing:

```bash
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

The release build talks to **`https://dondevolar.aquiles.dev`** by default
(`lib/config/api_config.dart`). Override only for dev:

```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://...
```

## Play Console checklist

1. **Create app** → Production (or internal testing first).
2. **Upload** `app-release.aab` under Release → Production (or Testing).
3. **Store listing** — copy from `store/listing.md` (EN + `es-419` Spanish).
4. **Graphics** — from `store/marketing/en/android_phone/` and
   `store/play/feature_graphic_en.png` (Spanish: `es/` paths).
5. **Privacy policy** — `https://dondevolar.aquiles.dev/privacy` (linked in-app).
6. **Data safety** — declare location (map “locate me”), network, account data if
   social features are enabled for this build.
7. **Content rating** — complete the questionnaire (maps / location / user content).
8. **App signing** — use **Google Play App Signing**; upload key = your
   `upload-keystore.jks`. Run `scripts/setup_android_signing.sh` to print SHA-1/256
   if needed for API restrictions.

## Release notes (v1.0.0)

See **Release notes** section in `store/listing.md`.

## Keystore backup

Losing `upload-keystore.jks` or its passwords blocks future updates. Keep an
offline backup; Play App Signing protects users if you enroll.
