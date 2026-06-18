import 'package:test/test.dart';
import 'package:zones_api_client/src/zone_identity.dart';

void main() {
  group('ZoneIdentity', () {
    test('pairs SAR, CTR, and TMA names across sources', () {
      expect(
        ZoneIdentity.matchKey(
            'SAR 01 CAPITAL FEDERAL - AVELLANEDA Y NORTE DE LANÚS'),
        'sar_1',
      );
      expect(ZoneIdentity.matchKey('SAR 01 Capital Federal'), 'sar_1');
      expect(ZoneIdentity.matchKey('EZEIZA CTR'), 'ctr_EZEIZA');
      expect(ZoneIdentity.matchKey('CTR EZEIZA'), 'ctr_EZEIZA');
      expect(
        ZoneIdentity.matchKey('AEROPARQUE JORGE NEWBERY CTR'),
        'ctr_AEROPARQUE',
      );
      expect(ZoneIdentity.matchKey('TMA BAIRES'), 'tma_BAIRES');
      expect(ZoneIdentity.matchKey('TMA BAIRES II'), 'tma_BAIRES');
    });

    test('distinct SAR designators never collapse to the same key', () {
      // The merge contract relies on distinct designators having distinct keys.
      // A collision here would silently drop one real restricted area.
      final keys = <String?>{};
      for (var n = 1; n <= 85; n++) {
        final padded = n.toString().padLeft(2, '0');
        final key = ZoneIdentity.matchKey('SAR $padded Zona Restringida');
        expect(key, 'sar_$n');
        expect(keys.add(key), isTrue, reason: 'duplicate key for SAR $padded');
      }
    });

    test('distinct CTR and TMA designators produce distinct keys', () {
      final designators = [
        'EZEIZA CTR',
        'AEROPARQUE JORGE NEWBERY CTR',
        'CORDOBA CTR',
        'MENDOZA CTR',
        'TMA BAIRES',
        'TMA CORDOBA',
        'TMA MENDOZA',
      ];
      final keys = designators.map(ZoneIdentity.matchKey).toList();
      expect(keys.whereType<String>(), hasLength(designators.length));
      expect(keys.toSet(), hasLength(designators.length));
    });
  });
}
