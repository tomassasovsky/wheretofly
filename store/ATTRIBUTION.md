# Store asset attributions

## Device frame PNGs

Marketing phone mockups use device frames from
[device-frames-media](https://github.com/jonnyjackson26/device-frames-media),
vendored under `tooling/store_assets/device-frames/`:

| Platform | Device | Variant |
|----------|--------|---------|
| iOS marketing (`ios_*`) | iPhone 16 Pro Max | Black Titanium |
| Android marketing (`android_phone/`) | Pixel 9 Pro | Obsidian |
| Android tablet marketing (optional frame asset) | Pixel Tablet | Hazel |

Refresh vendored files:

```bash
./tooling/store_assets/download_device_frames.sh
```

The upstream repository did not publish an SPDX license file at the time these
assets were added. If you redistribute the frame PNGs, confirm terms with the
maintainer or replace them with frames you have rights to use.
