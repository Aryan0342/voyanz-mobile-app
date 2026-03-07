import 'package:voyanz/features/reviews/data/reviews_history_data_source.dart';

class ReviewsHistoryRepository {
  final ReviewsHistoryDataSource _ds;

  ReviewsHistoryRepository(this._ds);

  Future<List<dynamic>> getCustomerHistory() => _ds.getCustomerHistory();
  Future<List<dynamic>> getProfessionalHistory() =>
      _ds.getProfessionalHistory();
  Future<List<dynamic>> getCustomerReviews() => _ds.getCustomerReviews();
  Future<List<dynamic>> getProfessionalReviews() =>
      _ds.getProfessionalReviews();
  Future<void> postReview(Map<String, dynamic> body) => _ds.postReview(body);
  Future<Map<String, dynamic>> getCustomerPricing() => _ds.getCustomerPricing();
  Future<Map<String, dynamic>> checkPromoCode(String code) =>
      _ds.checkPromoCode(code);
}
