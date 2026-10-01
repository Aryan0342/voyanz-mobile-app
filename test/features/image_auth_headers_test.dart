import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/core/network/authenticated_image.dart';

// Since 2026-09-29 `GET /api/1.0/chat/image/:chme_id` needs
// `Authorization: Bearer` + `x-api-key`; without them it answers
// `token_mandatory` as JSON and the image renders broken.
void main() {
  group('image auth headers', () {
    test('a relative path is ours, so it gets credentials', () {
      expect(isOwnApiUrl('/api/1.0/chat/image/42'), isTrue);
      expect(isOwnApiUrl('api/1.0/chat/image/42'), isTrue);
    });

    test('an absolute URL on the API host is ours', () {
      expect(isOwnApiUrl('https://voyanz.com/api/1.0/chat/image/42'), isTrue);
      expect(isOwnApiUrl('https://VOYANZ.com/api/1.0/chat/image/42'), isTrue);
    });

    // The bearer token must never leave our origin.
    test('a third-party host gets no credentials', () {
      expect(isOwnApiUrl('https://cdn.example.com/avatar.png'), isFalse);
      expect(imageAuthHeaders('https://cdn.example.com/avatar.png'), isEmpty);
      expect(
        imageAuthHeaders('https://evil.test/voyanz.com/pic.png'),
        isEmpty,
      );
    });

    test('empty and unparseable urls get nothing', () {
      expect(isOwnApiUrl(''), isFalse);
      expect(isOwnApiUrl('   '), isFalse);
      expect(imageAuthHeaders(''), isEmpty);
    });

    // The api key always goes to our own host, with or without a session.
    test('our own host always receives the api key', () {
      final headers = imageAuthHeaders('/api/1.0/chat/image/42');
      expect(headers.containsKey('x-api-key'), isTrue);
    });
  });
}
