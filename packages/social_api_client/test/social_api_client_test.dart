import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:social_api_client/social_api_client.dart';
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
  group('SocialApiClient', () {
    final baseUrl = Uri.parse('http://localhost:8080');

    SocialApiClient buildClient(
      _FakeHttpClient fake, {
      String? token = 'token',
    }) {
      return SocialApiClient(
        baseUrl: baseUrl,
        accessTokenProvider: () async => token,
        httpClient: fake,
      );
    }

    test('fetchFeed parses the posts array', () async {
      final fake = _FakeHttpClient(
        body: jsonEncode({
          'posts': [
            {
              'id': 'p1',
              'caption': 'Nice flight',
              'createdAt': '2024-01-01T00:00:00Z',
              'author': {'handle': 'pilot', 'displayName': 'Pilot'},
            },
          ],
        }),
      );

      final posts = await buildClient(fake).fetchFeed();

      expect(posts, hasLength(1));
      expect(posts.first.id, 'p1');
      expect(posts.first.author.handle, 'pilot');
      expect(fake.lastRequest!.url.path, '/v1/posts');
    });

    test('throws 401 when unauthenticated', () async {
      final fake = _FakeHttpClient();

      await expectLater(
        buildClient(fake, token: null).fetchFeed(),
        throwsA(
          isA<SocialApiException>()
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('surfaces the server error message on a 4xx response', () async {
      final fake = _FakeHttpClient(
        statusCode: 403,
        body: jsonEncode({'error': 'Forbidden'}),
      );

      await expectLater(
        buildClient(fake).fetchPost('p1'),
        throwsA(
          isA<SocialApiException>()
              .having((e) => e.message, 'message', 'Forbidden')
              .having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });

    test('throws on a malformed (non-JSON) body', () async {
      final fake = _FakeHttpClient(statusCode: 500, body: 'not json');

      await expectLater(
        buildClient(fake).fetchPost('p1'),
        throwsA(
          isA<SocialApiException>()
              .having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('fetchComments injects the postId and returns a list', () async {
      final fake = _FakeHttpClient(
        body: jsonEncode({
          'comments': [
            {
              'id': 'c1',
              'body': 'Great!',
              'createdAt': '2024-01-01T00:00:00Z',
              'author': {'handle': 'a', 'displayName': 'A'},
            },
          ],
        }),
      );

      final comments = await buildClient(fake).fetchComments('p1');

      expect(comments, hasLength(1));
      expect(comments.first.postId, 'p1');
    });
  });
}
