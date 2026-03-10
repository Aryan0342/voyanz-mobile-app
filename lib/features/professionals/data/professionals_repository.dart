import 'package:voyanz/core/config/mock_backend.dart';
import 'package:voyanz/features/professionals/data/professionals_data_source.dart';
import 'package:voyanz/features/professionals/models/professional.dart';

class ProfessionalsRepository {
  final ProfessionalsDataSource _ds;

  ProfessionalsRepository(this._ds);

  Future<List<Professional>> getProfessionals() async {
    if (kUseMockBackend) {
      return const [
        Professional(
          coId: 'pro-001',
          firstName: 'Amelie',
          lastName: 'Laurent',
          specialty: 'Tarot & Intuition',
          rating: 4.9,
          pricePerMinute: 3,
          isOnline: true,
        ),
        Professional(
          coId: 'pro-002',
          firstName: 'Noah',
          lastName: 'Bennett',
          specialty: 'Astrology Guidance',
          rating: 4.7,
          pricePerMinute: 2,
          isOnline: true,
        ),
        Professional(
          coId: 'pro-003',
          firstName: 'Lina',
          lastName: 'Moreau',
          specialty: 'Energy Reading',
          rating: 4.8,
          pricePerMinute: 4,
          isOnline: false,
        ),
      ];
    }
    return _ds.getProfessionals();
  }

  Future<ProfessionalDetail> getProfessionalInfos(String coId) async {
    if (kUseMockBackend) {
      final map = <String, ProfessionalDetail>{
        'pro-001': ProfessionalDetail(
          coId: 'pro-001',
          firstName: 'Amelie',
          lastName: 'Laurent',
          specialty: 'Tarot & Intuition',
          rating: 4.9,
          pricePerMinute: 3,
          isOnline: true,
          description:
              'Specialized in compassionate tarot consultations and decision support.',
          phone: '+33 6 11 22 33 44',
          email: 'amelie@voyanz.mock',
        ),
        'pro-002': ProfessionalDetail(
          coId: 'pro-002',
          firstName: 'Noah',
          lastName: 'Bennett',
          specialty: 'Astrology Guidance',
          rating: 4.7,
          pricePerMinute: 2,
          isOnline: true,
          description:
              'Focus on natal chart interpretation and monthly forecasting.',
          phone: '+44 7700 900123',
          email: 'noah@voyanz.mock',
        ),
      };
      return map[coId] ??
          ProfessionalDetail(
            coId: coId,
            firstName: 'Voyanz',
            lastName: 'Advisor',
            specialty: 'General Consultation',
            rating: 4.5,
            pricePerMinute: 2,
            isOnline: true,
            description: 'Mock profile for offline development mode.',
            email: 'advisor@voyanz.mock',
          );
    }
    return _ds.getProfessionalInfos(coId);
  }

  Future<void> setProfessionalFavorite(String coId, bool isFavorite) async {
    if (kUseMockBackend) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return;
    }
    return _ds.setProfessionalFavorite(coId, isFavorite);
  }

  Future<List<dynamic>> getDisponibilities() async {
    if (kUseMockBackend) {
      return const [
        {
          'day': 'Monday',
          'slots': ['09:00', '11:30', '14:00'],
        },
        {
          'day': 'Tuesday',
          'slots': ['10:00', '13:00', '16:00'],
        },
      ];
    }
    return _ds.getDisponibilities();
  }

  Future<void> createDisponibility(Map<String, dynamic> data) async {
    if (kUseMockBackend) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return;
    }
    return _ds.createDisponibility(data);
  }
}
