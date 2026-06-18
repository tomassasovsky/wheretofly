import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:zones_api_client/zones_api_client.dart';

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  late http.Client httpClient;
  late NotamClient client;
  late String fixture;

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost'));
    fixture = File('test/fixtures/notam_ef_sample.html').readAsStringSync();
  });

  setUp(() {
    httpClient = _MockHttpClient();
    client = NotamClient(
      baseUrl: Uri.parse('https://ais.anac.gob.ar'),
      httpClient: httpClient,
    );
    // GET establishes the session cookie.
    when(() => httpClient.get(any())).thenAnswer(
      (_) async => http.Response('', 200, headers: {'set-cookie': 'sid=abc'}),
    );
  });

  test('establishes a session then POSTs the indicador and parses', () async {
    when(
      () => httpClient.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => http.Response(fixture, 200));

    final result = await client.fetchFir('-EF');
    expect(result.zones, hasLength(3));
    expect(result.ungeocodable, hasLength(2));

    final captured = verify(
      () => httpClient.post(
        captureAny(),
        headers: captureAny(named: 'headers'),
        body: captureAny(named: 'body'),
      ),
    ).captured;
    final uri = captured[0] as Uri;
    final headers = captured[1] as Map<String, String>;
    final body = captured[2] as Map<String, String>;
    expect(uri.path, '/notam/pib');
    expect(body['indicador'], '-EF');
    expect(headers['Cookie'], 'sid=abc');
    expect(headers['X-Requested-With'], 'XMLHttpRequest');
  });

  test('throws NotamException on a non-200 response', () {
    when(
      () => httpClient.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => http.Response('error', 503));

    expect(client.fetchFir('-EF'), throwsA(isA<NotamException>()));
  });

  test('fetchAllFirs skips a failing FIR and merges the rest', () async {
    var call = 0;
    when(
      () => httpClient.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async {
      call++;
      // First FIR fails; the rest return the fixture.
      return call == 1
          ? http.Response('boom', 500)
          : http.Response(fixture, 200);
    });

    final result = await client.fetchAllFirs();
    // 4 successful FIRs × 3 zones each.
    expect(result.zones, hasLength(3 * (NotamClient.firCodes.length - 1)));
  });
}
