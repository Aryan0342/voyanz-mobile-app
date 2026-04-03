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

  bool get isInProgress => normalizedStatus == 'inprogress';

  bool get isCompleted => normalizedStatus == 'completed';

  bool get isRejected => normalizedStatus == 'rejected';

  bool get isKnownSpecStatus =>
      isCalling || isInProgress || isCompleted || isRejected;

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

  bool get isWaiting => isCalling || (!isActive && !isTerminal);

  String get uiLabel {
    if (isCalling) return 'Calling';
    if (isInProgress) return 'In progress';
    if (isCompleted) return 'Completed';
    if (isRejected) return 'Rejected';
    return status.isEmpty ? 'Unknown' : status;
  }

  String get uiMessage {
    if (isCalling) {
      return 'The session is being connected. Please stay on this screen.';
    }
    if (isInProgress) {
      return 'The session is live. You can continue your consultation.';
    }
    if (isCompleted) {
      return 'This session has ended.';
    }
    if (isRejected) {
      return 'This session was rejected and cannot be joined.';
    }
    return 'Session status changed: ${status.isEmpty ? 'unknown' : status}.';
  }
}
