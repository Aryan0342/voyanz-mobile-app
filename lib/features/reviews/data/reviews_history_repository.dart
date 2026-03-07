import 'package:voyanz/core/config/mock_backend.dart';
import 'package:voyanz/features/reviews/data/reviews_history_data_source.dart';

class ReviewsHistoryRepository {
  final ReviewsHistoryDataSource _ds;

  ReviewsHistoryRepository(this._ds);

    Future<List<dynamic>> getCustomerHistory() async {
        if (kUseMockBackend) {
            return const [
                {
                    'se_type': 'Video Session',
                    'se_date': '2026-03-05 14:30',
                    'se_status': 'completed',
                },
                {
                    'se_type': 'Chat Session',
                    'se_date': '2026-03-03 10:15',
                    'se_status': 'completed',
                },
            ];
        }
        return _ds.getCustomerHistory();
    }

    Future<List<dynamic>> getProfessionalHistory() async {
        if (kUseMockBackend) {
            return const [
                {
                    'se_type': 'Consultation',
                    'se_date': '2026-03-04 09:00',
                    'se_status': 'pending',
                },
            ];
        }
        return _ds.getProfessionalHistory();
    }

    Future<List<dynamic>> getCustomerReviews() async {
        if (kUseMockBackend) {
            return const [
                {
                    're_rating': 5,
                    're_comment': 'Very accurate and kind session.',
                    're_date': '2026-03-05',
                },
                {
                    're_rating': 4,
                    're_comment': 'Helpful guidance for next month.',
                    're_date': '2026-02-27',
                },
            ];
        }
        return _ds.getCustomerReviews();
    }

    Future<List<dynamic>> getProfessionalReviews() async {
        if (kUseMockBackend) {
            return const [
                {
                    're_rating': 5,
                    're_comment': 'Excellent communicator and empathetic.',
                    're_date': '2026-03-02',
                },
            ];
        }
        return _ds.getProfessionalReviews();
    }

    Future<void> postReview(Map<String, dynamic> body) async {
        if (kUseMockBackend) {
            await Future<void>.delayed(const Duration(milliseconds: 250));
            return;
        }
        return _ds.postReview(body);
    }

    Future<Map<String, dynamic>> getCustomerPricing() async {
        if (kUseMockBackend) {
            return const {
                'Starter': '9 EUR/month',
                'Premium': '19 EUR/month',
                'Per Minute': '2 EUR/min',
            };
        }
        return _ds.getCustomerPricing();
    }

    Future<Map<String, dynamic>> checkPromoCode(String code) async {
        if (kUseMockBackend) {
            return {
                'code': code,
                'valid': code.toUpperCase() == 'VOYANZ10',
                'discount': code.toUpperCase() == 'VOYANZ10' ? 10 : 0,
            };
        }
        return _ds.checkPromoCode(code);
    }
}
