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

class ReviewEligibility {
  final int sessionCount;
  final int reviewCount;

  const ReviewEligibility({
    required this.sessionCount,
    required this.reviewCount,
  });

  bool get canReview => sessionCount > reviewCount;
}

final reviewEligibilityProvider =
    FutureProvider.family<ReviewEligibility, String>((
      ref,
      professionalId,
    ) async {
      final history = await ref.watch(customerHistoryProvider.future);
      final reviews = await ref.watch(customerReviewsProvider.future);
      final sessionCount = history.where((item) {
        if (item is! Map<String, dynamic>) return false;
        final type = (item['type'] ?? '').toString().toLowerCase();
        if (type.isNotEmpty && type != 'session') return false;
        return _containsProfessionalId(item, professionalId);
      }).length;
      final reviewCount = reviews.where((item) {
        return item is Map<String, dynamic> &&
            _containsProfessionalId(item, professionalId);
      }).length;
      return ReviewEligibility(
        sessionCount: sessionCount,
        reviewCount: reviewCount,
      );
    });

bool _containsProfessionalId(Map<String, dynamic> item, String id) {
  for (final key in const [
    'co_id_professional',
    'professional_id',
    'co_target_id',
    'co_id',
  ]) {
    if (item[key]?.toString() == id) return true;
  }
  for (final key in const ['professional', 'session', 'data']) {
    final nested = item[key];
    if (nested is Map<String, dynamic> && _containsProfessionalId(nested, id)) {
      return true;
    }
  }
  return false;
}
