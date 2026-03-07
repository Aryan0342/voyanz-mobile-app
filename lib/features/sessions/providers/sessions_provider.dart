import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/core/providers.dart';
import 'package:voyanz/features/sessions/data/sessions_data_source.dart';
import 'package:voyanz/features/sessions/data/sessions_repository.dart';
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
