import 'dart:convert';

import 'package:test/test.dart';
import 'package:zones_api_client/src/text_encoding.dart';

void main() {
  group('repairUtf8Text', () {
    test('repairs Latin-1 mojibake for Spanish accents', () {
      final sar = latin1.decode(
        utf8.encode('SAR 01 CAPITAL FEDERAL - AVELLANEDA Y NORTE DE LANÚS'),
      );
      final congreso = latin1.decode(utf8.encode('Congreso de la Nación'));

      expect(
        repairUtf8Text(sar),
        'SAR 01 CAPITAL FEDERAL - AVELLANEDA Y NORTE DE LANÚS',
      );
      expect(repairUtf8Text(congreso), 'Congreso de la Nación');
    });

    test('leaves valid UTF-8 unchanged', () {
      const original = 'SAR 01 Capital Federal — Avellaneda y norte de Lanús';
      expect(repairUtf8Text(original), original);
    });
  });
}
