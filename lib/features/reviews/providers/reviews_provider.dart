import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/core/providers.dart';
import 'package:voyanz/features/reviews/data/reviews_history_data_source.dart';
import 'package:voyanz/features/reviews/data/reviews_history_repository.dart';

final reviewsHistoryDataSourceProvider = Provider<ReviewsHistoryDataSource>((
  ref,
) {
  return ReviewsHistoryDataSource(ref.watch(dioProvider));
});

final reviewsHistoryRepositoryProvider = Provider<ReviewsHistoryRepository>((
  ref,
) {
  return ReviewsHistoryRepository(ref.watch(reviewsHistoryDataSourceProvider));
});

final customerHistoryProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(reviewsHistoryRepositoryProvider).getCustomerHistory();
});

final professionalHistoryProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(reviewsHistoryRepositoryProvider).getProfessionalHistory();
});

final customerReviewsProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(reviewsHistoryRepositoryProvider).getCustomerReviews();
});

final professionalReviewsProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(reviewsHistoryRepositoryProvider).getProfessionalReviews();
});

final customerPricingProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  return ref.watch(reviewsHistoryRepositoryProvider).getCustomerPricing();
});
