/// End-to-end wind tile decode against Open-Meteo (network + WASM).
@Tags(['network'])
library;

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:where_to_fly/map/wind/om/om_wasm_module.dart';
import 'package:where_to_fly/map/wind/om/open_meteo_wind_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'decodes a gust tile with non-transparent pixels',
    () async {
      await OmWasmModule.ensureInitialized();
      final data = OpenMeteoWindData();
      final image = await data.tileImage(
        const TileCoordinates(5, 8, 12),
      );
      final byteData = await image.toByteData();
      expect(byteData, isNotNull);
      final bytes = byteData!.buffer.asUint8List();
      var opaquePixels = 0;
      for (var i = 3; i < bytes.length; i += 4) {
        if (bytes[i] > 0) opaquePixels++;
      }
      expect(
        opaquePixels,
        greaterThan(100),
        reason: 'wind tile should contain visible gust data',
      );
      image.dispose();
    },
    skip:
        'Requires live Open-Meteo HTTP; flutter test blocks outbound requests',
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
