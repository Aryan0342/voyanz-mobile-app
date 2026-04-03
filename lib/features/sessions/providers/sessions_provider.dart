import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/core/providers.dart';
import 'package:voyanz/features/sessions/data/sessions_data_source.dart';
import 'package:voyanz/features/sessions/data/sessions_repository.dart';
import 'package:voyanz/features/sessions/models/session_status.dart';
import 'package:voyanz/features/sessions/models/video_token.dart';

final sessionsDataSourceProvider = Provider<SessionsDataSource>((ref) {
  return SessionsDataSource(ref.watch(dioProvider));
});

final sessionsRepositoryProvider = Provider<SessionsRepository>((ref) {
  return SessionsRepository(ref.watch(sessionsDataSourceProvider));
});

/// Fetch a video token for a given session.
final videoTokenProvider =
    FutureProvider.family<VideoToken, ({String seId, String coId})>((
      ref,
      params,
    ) async {
      return ref
          .watch(sessionsRepositoryProvider)
          .getVideoToken(seId: params.seId, coId: params.coId);
    });

final sessionStatusProvider = FutureProvider.family<SessionStatus, String>((
  ref,
  seId,
) async {
  return ref.watch(sessionsRepositoryProvider).getSessionStatus(seId);
});

final sessionStatusPollingProvider = StreamProvider.autoDispose
    .family<SessionStatus, String>((ref, seId) async* {
      var disposed = false;
      ref.onDispose(() {
        disposed = true;
      });

      while (!disposed) {
        final status = await ref
            .read(sessionsRepositoryProvider)
            .getSessionStatus(seId);
        yield status;

        if (status.isActive || status.isTerminal) {
          break;
        }

        await Future<void>.delayed(const Duration(seconds: 4));
      }
    });

final sessionStatusLivePollingProvider = StreamProvider.autoDispose
    .family<SessionStatus, String>((ref, seId) async* {
      var disposed = false;
      ref.onDispose(() {
        disposed = true;
      });

      while (!disposed) {
        final status = await ref
            .read(sessionsRepositoryProvider)
            .getSessionStatus(seId);
        yield status;

        if (status.isTerminal) {
          break;
        }

        await Future<void>.delayed(const Duration(seconds: 6));
      }
    });
