import 'package:flutter_test/flutter_test.dart';

/// Mirrors _reviewRatingOrNull in reviews_screen.dart. A professional's
/// review of a client carries no `rv_note` (§11.1), so an absent rating means
/// "not rated" — counting it as zero dragged the customer's average down and
/// drew a 0.0-star row on the card.
double? reviewRatingOrNull(Map<String, dynamic> review) {
  final raw = review['rv_note'] ?? review['re_rating'];
  if (raw == null) return null;
  final value = raw is num ? raw.toDouble() : double.tryParse(raw.toString());
  if (value == null || value <= 0) return null;
  return value;
}

double average(List<Map<String, dynamic>> reviews) {
  final rated = reviews.map(reviewRatingOrNull).whereType<double>().toList();
  if (rated.isEmpty) return 0;
  return rated.reduce((a, b) => a + b) / rated.length;
}

void main() {
  group('review rating', () {
    test('a review with no rv_note is not rated', () {
      expect(reviewRatingOrNull({'rv_text': 'Nice client'}), isNull);
      expect(reviewRatingOrNull({'rv_note': null}), isNull);
      expect(reviewRatingOrNull({'rv_note': 0}), isNull);
    });

    test('a real rating is read, as number or string', () {
      expect(reviewRatingOrNull({'rv_note': 5}), 5.0);
      expect(reviewRatingOrNull({'rv_note': '4'}), 4.0);
      expect(reviewRatingOrNull({'re_rating': 3.5}), 3.5);
    });

    // The live customer account showed 2.7 across 7 reviews because two
    // professional-written ones were averaged in as zeros.
    test('unrated reviews do not drag the average down', () {
      final reviews = [
        {'rv_note': 5},
        {'rv_note': 4},
        {'rv_text': 'pro review, no rating'},
        {'rv_text': 'another pro review'},
      ];
      expect(average(reviews), 4.5);
    });

    test('all-unrated gives no average rather than zero stars', () {
      expect(average([{'rv_text': 'a'}, {'rv_text': 'b'}]), 0);
    });
  });
}
