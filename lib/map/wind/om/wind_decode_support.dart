import 'package:wasm_run/wasm_run.dart';
import 'package:where_to_fly/map/wind_map_config.dart';

/// Whether this device can decode Open-Meteo `.om` wind tiles in-process.
abstract final class WindDecodeSupport {
  /// Wasmtime + SIMD (desktop, macOS, Android arm64-v8a).
  static Future<bool> localOmWasmWorks() async {
    final features = await wasmRuntimeFeatures();
    return features.supportedFeatures.simd;
  }

  /// Remote PNG tiles from `WIND_TILE_BASE_URL` (dev iOS workaround).
  static bool get hasRemoteTileServer =>
      WindMapConfig.windTileBaseUrl.isNotEmpty;

  static Future<bool> windTilesAvailable() async {
    if (await localOmWasmWorks()) return true;
    return hasRemoteTileServer;
  }
}
