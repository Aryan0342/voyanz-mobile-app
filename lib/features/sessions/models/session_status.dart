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
}
