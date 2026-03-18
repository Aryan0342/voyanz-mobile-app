import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/features/reviews/data/reviews_history_data_source.dart';
import 'package:voyanz/features/reviews/data/reviews_history_repository.dart';

class _FakeReviewsHistoryDataSource extends ReviewsHistoryDataSource {
  _FakeReviewsHistoryDataSource() : super(Dio());

  Map<String, dynamic>? postedReview;
  String? promoChecked;

  @override
  Future<void> postReview(Map<String, dynamic> body) async {
    postedReview = body;
  }

  @override
  Future<Map<String, dynamic>> checkPromoCode(String code) async {
    promoChecked = code;
    return {'valid': true, 'discount': 10};
  }

  @override
  Future<Map<String, dynamic>> getCustomerPricing() async {
    return {'Starter': '9 EUR/month'};
  }
}

void main() {
  test('review submit + promo check critical pricing/reviews flows', () async {
    final ds = _FakeReviewsHistoryDataSource();
    final repo = ReviewsHistoryRepository(ds);

    await repo.postReview({'re_rating': 5, 're_comment': 'Great'});
    final promo = await repo.checkPromoCode('VOYANZ10');
    final pricing = await repo.getCustomerPricing();

    expect(ds.postedReview?['re_rating'], 5);
    expect(ds.promoChecked, 'VOYANZ10');
    expect(promo['valid'], true);
    expect(pricing['Starter'], '9 EUR/month');
  });
}
