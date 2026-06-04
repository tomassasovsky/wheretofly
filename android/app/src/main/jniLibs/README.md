# 16 KB–aligned `libwasm_run_dart.so`

The `wasm_run_flutter` plugin ships prebuilt JNI libraries with 4 KB ELF alignment,
which fails Google Play’s 16 KB page-size requirement for Android 15+.

Release builds expect these files (not committed; ~28 MB total):

- `arm64-v8a/libwasm_run_dart.so`
- `x86_64/libwasm_run_dart.so`

Generate them from the repo root:

```bash
./scripts/rebuild_wasm_run_android_16k.sh
```

See `store/PLAY_RELEASE.md` and `scripts/verify_android_16k_alignment.sh`.
