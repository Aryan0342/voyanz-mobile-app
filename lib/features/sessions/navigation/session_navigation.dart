import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:voyanz/features/sessions/data/sessions_data_source.dart';
import 'package:voyanz/features/sessions/models/session_status.dart';
import 'package:voyanz/features/sessions/models/session_type.dart';

void openSessionRoute(
  BuildContext context, {
  required String type,
  required String seId,
  required String coId,
  String? chgrId,
  bool replace = false,
  bool wait = false,
}) {
  final normalizedType = normalizeSessionType(type);
  late final String route;
  if (normalizedType == 'video' && !wait) {
    route = '/video/$seId/$coId';
  } else if (normalizedType == 'phone' && !wait) {
    route = '/session/phone/$seId/$coId';
  } else if (normalizedType == 'chat' &&
      !wait &&
      chgrId != null &&
      chgrId.trim().isNotEmpty) {
    route = '/chat/${chgrId.trim()}';
  } else if (normalizedType == 'chat' && !wait) {
    route = '/session/chat/$seId/$coId';
  } else if (normalizedType == 'video' ||
      normalizedType == 'phone' ||
      normalizedType == 'chat') {
    route = '/session/wait/$normalizedType/$seId/$coId';
  } else {
    route = '/home';
  }

  if (replace) {
    context.pushReplacement(route);
  } else {
    context.push(route);
  }
}

void openLaunchResult(
  BuildContext context,
  SessionLaunchResult result, {
  required String fallbackType,
  required String coId,
  bool replace = false,
}) {
  final type = normalizeSessionType(result.seType) ?? fallbackType;
  final status = result.seStatus?.trim().toLowerCase();
  final shouldWait =
      status != null &&
      status.isNotEmpty &&
      status != 'inprogress' &&
      status != 'active' &&
      status != 'started';

  openSessionRoute(
    context,
    type: type,
    seId: result.sessionId,
    coId: coId,
    chgrId: result.chgrId,
    replace: replace,
    wait: shouldWait,
  );
}

void openSessionStatus(
  BuildContext context,
  SessionStatus status, {
  required String fallbackType,
  required String coId,
  String? fallbackChgrId,
  bool replace = false,
}) {
  final type = normalizeSessionType(status.sessionType) ?? fallbackType;
  openSessionRoute(
    context,
    type: type,
    seId: status.seId,
    coId: coId,
    chgrId: status.chgrId ?? fallbackChgrId,
    replace: replace,
    wait: !status.isActive,
  );
}
