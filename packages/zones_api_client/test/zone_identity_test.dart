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
  });
}
