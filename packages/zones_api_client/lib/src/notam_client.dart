import 'package:http/http.dart' as http;
import 'package:zones_api_client/src/models/zone_data.dart';
import 'package:zones_api_client/src/notam_parser.dart';

/// Thrown when the NOTAM feed cannot be fetched.
class NotamException implements Exception {
  const NotamException(this.message);
  final String message;
  @override
  String toString() => 'NotamException: $message';
}

/// Fetches live Argentine NOTAMs from EANA's public `POST /notam/pib` endpoint
/// and parses them into time-bounded zones.
///
/// The endpoint is an AJAX form behind a session cookie: a GET on the NOTAM
/// page establishes the session, then a form-urlencoded POST with the FIR
/// `indicador` returns an HTML `<table>`. This is an undocumented scrape
/// (HTML shape can change) and is reference-only — never present it as an
/// official PIB.
class NotamClient {
  NotamClient({Uri? baseUrl, http.Client? httpClient})
      : _base = baseUrl ?? Uri.parse('https://ais.anac.gob.ar'),
        _httpClient = httpClient ?? http.Client();

  /// FIR-wide indicator codes (EANA-internal, not ICAO): Ezeiza, Córdoba,
  /// Comodoro, Mendoza, Resistencia.
  static const firCodes = ['-EF', '-CF', '-VF', '-MF', '-RR'];

  final Uri _base;
  final http.Client _httpClient;

  /// Fetches and parses NOTAMs for a single FIR [indicador] (e.g. `-EF`).
  Future<NotamParseResult> fetchFir(String indicador) async {
    final cookie = await _establishSession();
    final response = await _post(indicador, cookie);
    if (response.statusCode != 200) {
      throw NotamException('HTTP ${response.statusCode} for $indicador');
    }
    return NotamParser.parse(response.body);
  }

  /// Fetches every FIR in [firCodes] and merges the results. A FIR that fails
  /// is skipped so one outage doesn't blank the whole feed.
  Future<NotamParseResult> fetchAllFirs() async {
    final zones = <ZoneData>[];
    final ungeocodable = <UngeocodableNotam>[];
    for (final code in firCodes) {
      try {
        final result = await fetchFir(code);
        zones.addAll(result.zones);
        ungeocodable.addAll(result.ungeocodable);
      } on Object {
        // Skip this FIR; partial coverage beats none.
      }
    }
    return NotamParseResult(zones: zones, ungeocodable: ungeocodable);
  }

  Future<String?> _establishSession() async {
    try {
      final response = await _httpClient
          .get(_base.replace(path: '/notam'))
          .timeout(const Duration(seconds: 12));
      return response.headers['set-cookie'];
    } catch (e) {
      throw NotamException('session error: $e');
    }
  }

  Future<http.Response> _post(String indicador, String? cookie) async {
    try {
      return await _httpClient.post(
        _base.replace(path: '/notam/pib'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'X-Requested-With': 'XMLHttpRequest',
          'Referer': _base.replace(path: '/notam').toString(),
          if (cookie != null) 'Cookie': cookie,
        },
        body: {'indicador': indicador},
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw NotamException('network error: $e');
    }
  }
}
