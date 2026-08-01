import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/core/providers.dart';
import 'package:voyanz/features/professionals/data/professionals_data_source.dart';
import 'package:voyanz/features/professionals/data/professionals_repository.dart';
import 'package:voyanz/features/professionals/models/professional.dart';

class FavoriteProfessionalsNotifier extends StateNotifier<Set<String>> {
  FavoriteProfessionalsNotifier() : super(<String>{});

  void setFavorite(String coId, bool isFavorite) {
    final next = <String>{...state};
    if (isFavorite) {
      next.add(coId);
    } else {
      next.remove(coId);
    }
    state = next;
  }
}

final favoriteProfessionalIdsProvider =
    StateNotifierProvider<FavoriteProfessionalsNotifier, Set<String>>((ref) {
      return FavoriteProfessionalsNotifier();
    });

final professionalsDataSourceProvider = Provider<ProfessionalsDataSource>((
  ref,
) {
  return ProfessionalsDataSource(ref.watch(dioProvider));
});

final professionalsRepositoryProvider = Provider<ProfessionalsRepository>((
  ref,
) {
  return ProfessionalsRepository(ref.watch(professionalsDataSourceProvider));
});

final professionalsListProvider = FutureProvider<List<Professional>>((
  ref,
) async {
  return ref.watch(professionalsRepositoryProvider).getProfessionals();
});

final professionalDetailProvider =
    FutureProvider.family<ProfessionalDetail, String>((ref, coId) async {
      return ref
          .watch(professionalsRepositoryProvider)
          .getProfessionalInfos(coId);
    });

final professionalDisponibilitiesProvider = FutureProvider<List<dynamic>>((
  ref,
) async {
  return ref.watch(professionalsRepositoryProvider).getDisponibilities();
});

const _monthShortNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatSlotDay(String isoDate) {
  final parts = isoDate.split('-');
  if (parts.length != 3) return isoDate;
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (month == null || day == null || month < 1 || month > 12) {
    return isoDate;
  }
  return '${_monthShortNames[month - 1]} $day';
}

String? _extractTime(String? dateTime) {
  if (dateTime == null || dateTime.isEmpty) return null;
  final sep = dateTime.indexOf('T');
  final timePart = sep >= 0 ? dateTime.substring(sep + 1) : dateTime;
  final match = RegExp(r'^(\d{2}):(\d{2})').firstMatch(timePart);
  if (match == null) return null;
  return '${match.group(1)}:${match.group(2)}';
}

final professionalBookingSlotsProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((
  ref,
  coId,
) async {
  final payload = await ref
      .watch(professionalsRepositoryProvider)
      .getProfessionalBookingSlots(coId);

  final rows = <Map<String, dynamic>>[];

  final next = payload['nextdisponibilities'];
  if (next is List) {
    for (final entry in next) {
      if (entry is! Map<String, dynamic>) continue;
      final date = entry['date']?.toString() ?? '';
      final hours = entry['hours'];
      final times = <String>[];
      if (hours is List) {
        for (final hour in hours) {
          if (hour is List && hour.isNotEmpty) {
            final time = hour.first.toString();
            if (time.isNotEmpty) times.add(time);
          } else if (hour is String && hour.trim().isNotEmpty) {
            times.add(hour.trim());
          }
        }
      }
      if (date.isEmpty || times.isEmpty) continue;
      rows.add({
        'key': 'slot_$date',
        'day': _formatSlotDay(date),
        'slots': times,
        'ap_id': null,
      });
    }
  }

  final appointments = payload['appointments'];
  if (appointments is List) {
    for (final appt in appointments) {
      if (appt is! Map<String, dynamic>) continue;
      final apId = appt['ap_id']?.toString() ?? '';
      if (apId.isEmpty) continue;
      final name = appt['ap_name']?.toString() ?? '';
      final date = appt['ap_date']?.toString() ?? '';
      final time = _extractTime(date);
      rows.add({
        'key': 'ap_$apId',
        'day': name.isNotEmpty
            ? name
            : (date.isNotEmpty ? date.substring(0, 10) : ''),
        'slots': time != null ? <String>[time] : <String>[],
        'ap_id': apId,
      });
    }
  }

  return rows;
});

final professionalDisponibilitiesPayloadProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
      return ref
          .watch(professionalsRepositoryProvider)
          .getDisponibilitiesPayload();
    });
