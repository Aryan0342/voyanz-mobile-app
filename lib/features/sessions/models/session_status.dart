import 'dart:convert';

import 'package:voyanz/core/l10n/app_translations.dart';

class SessionStatus {
  final String seId;
  final String status;
  final Map<String, dynamic> raw;

  const SessionStatus({
    required this.seId,
    required this.status,
    this.raw = const {},
  });

  factory SessionStatus.fromJson(String seId, Map<String, dynamic> json) {
    final normalizedSeId = (json['se_id'] ?? json['id'] ?? seId)
        .toString()
        .trim();

    final rawStatus =
        (json['se_status'] ?? json['status'] ?? json['state'] ?? 'pending')
            .toString()
            .trim();

    return SessionStatus(
      seId: normalizedSeId.isEmpty ? seId : normalizedSeId,
      status: rawStatus,
      raw: Map<String, dynamic>.from(json),
    );
  }

  String get normalizedStatus => status.toLowerCase();

  String? get sessionType => _firstNonEmpty([
    raw['se_type'],
    raw['session'] is Map<String, dynamic>
        ? (raw['session'] as Map<String, dynamic>)['se_type']
        : null,
  ]);

  String? get room => _firstNonEmpty([
    raw['se_room'],
    raw['session'] is Map<String, dynamic>
        ? (raw['session'] as Map<String, dynamic>)['se_room']
        : null,
  ]);

  String? get chgrId => _firstNonEmpty([
    raw['chgr_id'],
    raw['session'] is Map<String, dynamic>
        ? (raw['session'] as Map<String, dynamic>)['chgr_id']
        : null,
  ]);

  /// Scheduled appointment id — present for group/scheduled sessions
  /// (used to detect group sessions, WEBSOCKET §5.2).
  String? get apId => _firstNonEmpty([
    raw['ap_id'],
    raw['session'] is Map<String, dynamic>
        ? (raw['session'] as Map<String, dynamic>)['ap_id']
        : null,
  ]);

  String? get professionalCoId => _firstNonEmpty([
    raw['co_id_professional'],
    raw['session'] is Map<String, dynamic>
        ? (raw['session'] as Map<String, dynamic>)['co_id_professional']
        : null,
  ]);

  String? get customerCoId => _firstNonEmpty([
    raw['co_id_customer'],
    raw['session'] is Map<String, dynamic>
        ? (raw['session'] as Map<String, dynamic>)['co_id_customer']
        : null,
  ]);

  /// Whether the professional has actually joined the session (presence).
  ///
  /// The backend records connected participants in `se_connections`
  /// (JSON object keyed by co_id). A freshly created REST session has an
  /// empty/absent `se_connections`, so this stays false until the pro joins.
  bool get isProfessionalPresent {
    final proId = professionalCoId;
    if (proId == null || proId.trim().isEmpty) return false;

    final connections = _firstNonEmpty([
      raw['se_connections'],
      raw['session'] is Map<String, dynamic>
          ? (raw['session'] as Map<String, dynamic>)['se_connections']
          : null,
    ]);
    if (connections == null || connections.trim().isEmpty) return false;

    try {
      final decoded = jsonDecode(connections);
      if (decoded is Map) {
        return decoded.keys.any(
          (key) => key.toString().trim() == proId.trim(),
        );
      }
    } catch (_) {}

    return connections.contains(proId.trim());
  }

  bool get isCalling => normalizedStatus == 'calling';

  bool get isAccepted => normalizedStatus == 'accepted';

  bool get isPending => normalizedStatus == 'pending';

  bool get isInProgress => normalizedStatus == 'inprogress';

  bool get isCompleted => normalizedStatus == 'completed';

  bool get isRejected => normalizedStatus == 'rejected';

  bool get isCanceled =>
      normalizedStatus == 'canceled' || normalizedStatus == 'cancelled';

  /// The pro answered the phone but did not press key 1 within the
  /// confirmation window (anti-voicemail protection).
  bool get isNoStarConfirm =>
      normalizedStatus == 'professional_no_star_confirm' ||
      normalizedStatus == 'no_star_confirm';

  bool get isKnownSpecStatus =>
      isCalling ||
      isAccepted ||
      isPending ||
      isInProgress ||
      isCompleted ||
      isRejected ||
      isCanceled ||
      isNoStarConfirm;

  bool get isActive {
    return isInProgress;
  }

  bool get isTerminal {
    switch (normalizedStatus) {
      case 'ended':
      case 'finished':
      case 'closed':
      case 'cancelled':
      case 'canceled':
      case 'rejected':
      case 'declined':
      case 'expired':
      case 'timeout':
      case 'failed':
      case 'professional_no_star_confirm':
      case 'no_star_confirm':
        return true;
      default:
        return isCompleted || isRejected;
    }
  }

  bool get isWaiting =>
      isCalling || isAccepted || isPending || (!isActive && !isTerminal);

  String localizedLabel(AppTranslations t) {
    if (isCalling) return t.sessionStatusCallingLabel;
    if (isAccepted) return t.sessionStatusAcceptedLabel;
    if (isPending) return t.sessionStatusPendingLabel;
    if (isInProgress) return t.sessionStatusInProgressLabel;
    if (isCompleted) return t.sessionStatusCompletedLabel;
    if (isRejected) return t.sessionStatusRejectedLabel;
    if (isCanceled) return t.sessionStatusCanceledLabel;
    if (isNoStarConfirm) return t.sessionStatusNoStarConfirmLabel;
    return t.sessionStatusUnknownLabel(status);
  }

  String localizedMessage(AppTranslations t, {required bool isProfessional}) {
    if (isCalling) {
      return t.sessionStatusCallingMessage(isProfessional: isProfessional);
    }
    if (isAccepted) {
      return t.sessionStatusAcceptedMessage(isProfessional: isProfessional);
    }
    if (isPending) {
      return t.sessionStatusPendingMessage(isProfessional: isProfessional);
    }
    if (isInProgress) {
      return t.sessionStatusInProgressMessage(isProfessional: isProfessional);
    }
    if (isCompleted) {
      return t.sessionStatusCompletedMessage;
    }
    if (isRejected) {
      return t.sessionStatusRejectedMessage;
    }
    if (isCanceled) {
      return t.sessionStatusCanceledMessage;
    }
    if (isNoStarConfirm) {
      return t.sessionStatusNoStarConfirmMessage;
    }
    return t.sessionStatusChangedMessage(status);
  }

  static String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty && text != 'null') return text;
    }
    return null;
  }
}
