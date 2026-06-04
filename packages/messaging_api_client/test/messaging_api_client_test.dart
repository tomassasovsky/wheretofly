import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:messaging_api_client/messaging_api_client.dart';
import 'package:test/test.dart';

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient({this.statusCode = 200, this.body = '{}'});

  int statusCode;
  String body;
  http.BaseRequest? lastRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request;
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(body)),
      statusCode,
      headers: const {'content-type': 'application/json'},
    );
  }
}

void main() {
  group('MessagingApiClient', () {
    final baseUrl = Uri.parse('http://localhost:8080');

    MessagingApiClient buildClient(
      _FakeHttpClient fake, {
      String? token = 'token',
    }) {
      return MessagingApiClient(
        baseUrl: baseUrl,
        accessTokenProvider: () async => token,
        httpClient: fake,
      );
    }

    test('fetchMessages parses messages and injects the threadId', () async {
      final fake = _FakeHttpClient(
        body: jsonEncode({
          'messages': [
            {
              'id': 'm1',
              'senderId': 'u1',
              'body': 'Hi',
              'createdAt': '2024-01-01T00:00:00Z',
            },
          ],
        }),
      );

      final messages = await buildClient(fake).fetchMessages('t1');

      expect(messages, hasLength(1));
      expect(messages.first.threadId, 't1');
      expect(messages.first.body, 'Hi');
    });

    test('sendMessage parses the created message', () async {
      final fake = _FakeHttpClient(
        body: jsonEncode({
          'id': 'm2',
          'senderId': 'u1',
          'body': 'Hello',
          'createdAt': '2024-01-01T00:00:00Z',
        }),
      );

      final message = await buildClient(fake).sendMessage(
        threadId: 't1',
        body: 'Hello',
      );

      expect(message.id, 'm2');
      expect(message.threadId, 't1');
    });

    test('throws 401 when unauthenticated', () async {
      final fake = _FakeHttpClient();

      await expectLater(
        buildClient(fake, token: null).fetchThreads(),
        throwsA(
          isA<MessagingApiException>()
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('updateNotificationPreferences round-trips the prefs', () async {
      final fake = _FakeHttpClient(
        body: jsonEncode({
          'follows': false,
          'messages': true,
          'comments': false,
          'weather': true,
        }),
      );

      final updated = await buildClient(fake).updateNotificationPreferences(
        const NotificationPreferences(
          follows: false,
          messages: true,
          comments: false,
          weather: true,
        ),
      );

      expect(updated.follows, isFalse);
      expect(updated.comments, isFalse);
      expect(fake.lastRequest!.method, 'PATCH');
    });

    test('surfaces the server error message on a 4xx response', () async {
      final fake = _FakeHttpClient(
        statusCode: 400,
        body: jsonEncode({'error': 'Bad thread'}),
      );

      await expectLater(
        buildClient(fake).fetchMessages('t1'),
        throwsA(
          isA<MessagingApiException>()
              .having((e) => e.message, 'message', 'Bad thread'),
        ),
      );
    });
  });
}
