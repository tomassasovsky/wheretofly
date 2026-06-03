import 'package:flutter_test/flutter_test.dart';
import 'package:where_to_fly/map/wind_map_bridge.dart';

void main() {
  group('WindMapBridgeMessage', () {
    test('decode mapReady', () {
      final message = WindMapBridgeMessage.decode('{"type":"mapReady"}');
      expect(message.type, WindMapMessageType.mapReady);
    });

    test('decode windError with message', () {
      final message = WindMapBridgeMessage.decode(
        '{"type":"windError","message":"tile failed"}',
      );
      expect(message.type, WindMapMessageType.windError);
      expect(message.message, 'tile failed');
    });
  });

  group('WindMapBridgeCommands', () {
    test('init escapes style URL and passes omSourceUrl', () {
      final script = WindMapBridgeCommands.init(
        styleUrl: "https://example.com/style.json?key=ab'c",
        lat: -38.4,
        lon: -63.6,
        zoom: 4.5,
        shellTimeoutMs: 20000,
        omSourceUrl: 'https://map-tiles.open-meteo.com/data_spatial/dwd_icon/'
            'latest.json?time_step=current_time_1H&variable=wind_gusts_10m',
      );
      expect(script, contains('WindMapApp.init'));
      expect(script, contains('omSourceUrl:'));
      expect(script, contains('wind_gusts_10m'));
      expect(script, contains(r"ab\'c"));
    });
  });
}
