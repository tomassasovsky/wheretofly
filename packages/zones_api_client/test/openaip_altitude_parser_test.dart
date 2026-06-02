import 'package:test/test.dart';
import 'package:zones_api_client/src/openaip_altitude_parser.dart';

void main() {
  group('OpenAipAltitudeLimits', () {
    test('parses MSL lower ceiling in feet', () {
      final limits = OpenAipAltitudeLimits.fromAirspaceJson({
        'lowerCeiling': {
          'value': 3000,
          'unit': 'FT',
          'referenceDatum': 'MSL',
        },
        'upperCeiling': {'value': 'UNL'},
      });
      expect(limits.lowerMetersMsl, closeTo(914.4, 0.1));
      expect(limits.upperMetersMsl, isNull);
      expect(limits.hasParsedLimits, isTrue);
    });

    test('parses GND AGL band', () {
      final limits = OpenAipAltitudeLimits.fromAirspaceJson({
        'lowerCeiling': {'value': 0, 'unit': 'FT', 'referenceDatum': 'GND'},
        'upperCeiling': {'value': 500, 'unit': 'FT', 'referenceDatum': 'GND'},
      });
      expect(limits.lowerMetersAgl, 0);
      expect(limits.upperMetersAgl, closeTo(152.4, 0.1));
    });

    test('missing limits — hasParsedLimits is false', () {
      const limits = OpenAipAltitudeLimits();
      expect(limits.hasParsedLimits, isFalse);
    });

    test('parses string limit with AMSL datum', () {
      final limits = OpenAipAltitudeLimits.fromAirspaceJson({
        'lowerLimit': '1500FTAMSL',
      });
      expect(limits.lowerMetersMsl, closeTo(457.2, 0.5));
    });
  });
}
