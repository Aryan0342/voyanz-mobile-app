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

  bool get isCalling => normalizedStatus == 'calling';

  bool get isAccepted => normalizedStatus == 'accepted';

  bool get isPending => normalizedStatus == 'pending';

  bool get isInProgress => normalizedStatus == 'inprogress';

  bool get isCompleted => normalizedStatus == 'completed';

  bool get isRejected => normalizedStatus == 'rejected';

  bool get isCanceled =>
      normalizedStatus == 'canceled' || normalizedStatus == 'cancelled';

  bool get isKnownSpecStatus =>
      isCalling ||
      isAccepted ||
      isPending ||
      isInProgress ||
      isCompleted ||
      isRejected ||
      isCanceled;

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
