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

    test('parses numeric referenceDatum from export files', () {
      final limits = OpenAipAltitudeLimits.fromAirspaceJson({
        'lowerLimit': {'value': 0, 'unit': 1, 'referenceDatum': 0},
        'upperLimit': {'value': 2500, 'unit': 1, 'referenceDatum': 1},
      });
      expect(limits.lowerMetersAgl, 0);
      expect(limits.upperMetersMsl, closeTo(762, 1));
      expect(limits.describe(), 'GND – 2500 ft MSL');
    });

    test('parses numeric unit codes from export files', () {
      final limits = OpenAipAltitudeLimits.fromAirspaceJson({
        'lowerLimit': {'value': 500, 'unit': 0, 'referenceDatum': 0},
        'upperLimit': {'value': 120, 'unit': 0, 'referenceDatum': 0},
      });
      expect(limits.lowerMetersAgl, 500);
      expect(limits.upperMetersAgl, 120);
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
