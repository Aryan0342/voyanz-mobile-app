import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/features/reviews/models/review_client.dart';

/// Captured from GET /web/1.0/professional/reviews on voyanz.com, 2026-09-27.
const _body = {
  'reviews': [
    {'rv_id': 9, 'rv_ispro': false, 'rv_note': 5, 'rv_text': 'nice experience'},
  ],
  'reviewspro': [],
  'mycustomers': [
    {'key': 0, 'value': 'Choisir un client'},
    {'key': 184, 'value': 'Shahzeb QA'},
    {'key': 292, 'value': 'Marie-christine Gagnon'},
  ],
  'err': null,
  'meta': {},
};

void main() {
  group('ReviewClient.listFrom', () {
    test('reads the clients a professional may review', () {
      final clients = ReviewClient.listFrom(_body);
      expect(clients.map((c) => c.id), ['184', '292']);
      expect(clients.map((c) => c.name), ['Shahzeb QA', 'Marie-christine Gagnon']);
    });

    // The server's first row is a placeholder, and its label is hardcoded
    // French, so it must not reach a Spanish or English professional.
    test('drops the placeholder row', () {
      final clients = ReviewClient.listFrom(_body);
      expect(clients.any((c) => c.id == '0'), isFalse);
      expect(clients.any((c) => c.name.contains('Choisir')), isFalse);
    });

    test('accepts the data envelope', () {
      expect(ReviewClient.listFrom({'data': _body}), hasLength(2));
    });

    test('tolerates string keys', () {
      final clients = ReviewClient.listFrom({
        'mycustomers': [
          {'key': '0', 'value': 'Choisir un client'},
          {'key': '184', 'value': 'Shahzeb QA'},
        ],
      });
      expect(clients.single.id, '184');
    });

    test('a client without a name falls back to the id', () {
      final clients = ReviewClient.listFrom({
        'mycustomers': [
          {'key': 184, 'value': ''},
        ],
      });
      expect(clients.single.name, '184');
    });

    test('a missing or malformed list is empty, not an error', () {
      expect(ReviewClient.listFrom(const {}), isEmpty);
      expect(ReviewClient.listFrom(null), isEmpty);
      expect(ReviewClient.listFrom(const {'mycustomers': 'nope'}), isEmpty);
      expect(ReviewClient.listFrom(const {'mycustomers': [1, 'x']}), isEmpty);
    });
  });

  group('rv_ispro', () {
    // The spec says integer 0/1 but the documented response example and the
    // live server both return a boolean, so reading it must accept either.
    test('the live response returns a boolean', () {
      final received = (_body['reviews'] as List).first as Map;
      expect(received['rv_ispro'], isA<bool>());
    });
  });
}
