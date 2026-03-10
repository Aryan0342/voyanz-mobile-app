import 'package:voyanz/core/config/mock_backend.dart';
import 'package:voyanz/features/reviews/data/reviews_history_data_source.dart';

class ReviewsHistoryRepository {
  final ReviewsHistoryDataSource _ds;

  ReviewsHistoryRepository(this._ds);

  Future<List<dynamic>> getCustomerHistory() async {
    if (kUseMockBackend) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return const [
        {
          'se_id': 1001,
          'se_type': 'Video Call',
          'se_date': '2026-03-10 15:30',
          'se_status': 'completed',
          'se_duration': '45 min',
          'co_id': 'pro001',
          'co_fullname': 'Sarah Johnson',
        },
        {
          'se_id': 1002,
          'se_type': 'Phone Call',
          'se_date': '2026-03-08 14:15',
          'se_status': 'completed',
          'se_duration': '30 min',
          'co_id': 'pro002',
          'co_fullname': 'Michael Chen',
        },
        {
          'se_id': 1003,
          'se_type': 'Chat Session',
          'se_date': '2026-03-05 10:45',
          'se_status': 'completed',
          'se_duration': '20 min',
          'co_id': 'pro003',
          'co_fullname': 'Emma Williams',
        },
        {
          'se_id': 1004,
          'se_type': 'Video Call',
          'se_date': '2026-03-01 16:00',
          'se_status': 'cancelled',
          'se_duration': '0 min',
          'co_id': 'pro001',
          'co_fullname': 'Sarah Johnson',
        },
        {
          'se_id': 1005,
          'se_type': 'Phone Call',
          'se_date': '2026-02-28 11:30',
          'se_status': 'completed',
          'se_duration': '25 min',
          'co_id': 'pro004',
          'co_fullname': 'David Martinez',
        },
      ];
    }
    return _ds.getCustomerHistory();
  }

  Future<List<dynamic>> getProfessionalHistory() async {
    if (kUseMockBackend) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return const [
        {
          'se_id': 2001,
          'se_type': 'Video Call',
          'se_date': '2026-03-10 10:00',
          'se_status': 'completed',
          'se_duration': '50 min',
          'co_id': 'cust001',
          'co_fullname': 'Alice Cooper',
        },
        {
          'se_id': 2002,
          'se_type': 'Phone Call',
          'se_date': '2026-03-09 14:30',
          'se_status': 'completed',
          'se_duration': '35 min',
          'co_id': 'cust002',
          'co_fullname': 'Bob Smith',
        },
        {
          'se_id': 2003,
          'se_type': 'Chat Session',
          'se_date': '2026-03-07 09:00',
          'se_status': 'pending',
          'se_duration': '15 min',
          'co_id': 'cust003',
          'co_fullname': 'Carol White',
        },
        {
          'se_id': 2004,
          'se_type': 'Video Call',
          'se_date': '2026-03-04 15:45',
          'se_status': 'completed',
          'se_duration': '1h',
          'co_id': 'cust004',
          'co_fullname': 'Diana Green',
        },
      ];
    }
    return _ds.getProfessionalHistory();
  }

  Future<List<dynamic>> getCustomerReviews() async {
    if (kUseMockBackend) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return const [
        {
          're_id': 501,
          're_rating': 5,
          're_comment': 'Very accurate and kind session. Highly recommended!',
          're_date': '2026-03-10',
          'co_fullname': 'Sarah Johnson',
          'co_id': 'pro001',
        },
        {
          're_id': 502,
          're_rating': 4,
          're_comment': 'Helpful guidance for next month.',
          're_date': '2026-03-08',
          'co_fullname': 'Michael Chen',
          'co_id': 'pro002',
        },
        {
          're_id': 503,
          're_rating': 5,
          're_comment': 'Excellent insights and very supportive.',
          're_date': '2026-03-05',
          'co_fullname': 'Emma Williams',
          'co_id': 'pro003',
        },
        {
          're_id': 504,
          're_rating': 4,
          're_comment': 'Good session, very professional.',
          're_date': '2026-02-28',
          'co_fullname': 'David Martinez',
          'co_id': 'pro004',
        },
      ];
    }
    return _ds.getCustomerReviews();
  }

  Future<List<dynamic>> getProfessionalReviews() async {
    if (kUseMockBackend) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return const [
        {
          're_id': 601,
          're_rating': 5,
          're_comment': 'Excellent communicator and empathetic.',
          're_date': '2026-03-10',
          'co_fullname': 'Alice Cooper',
          'co_id': 'cust001',
        },
        {
          're_id': 602,
          're_rating': 5,
          're_comment': 'Very professional and punctual.',
          're_date': '2026-03-09',
          'co_fullname': 'Bob Smith',
          'co_id': 'cust002',
        },
        {
          're_id': 603,
          're_rating': 4,
          're_comment': 'Great session, helpful advice.',
          're_date': '2026-03-04',
          'co_fullname': 'Diana Green',
          'co_id': 'cust004',
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
