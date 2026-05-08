import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/core/network/websocket_service.dart';
import 'package:voyanz/core/providers.dart';

/// WebSocket service provider
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return WebSocketService(tokenStorage);
});

/// Session started event model
class SessionStartedEvent {
  final String seId;
  final String seStatus;
  final String seType; // 'video', 'phone', 'chat'
  final String seRoom;
  final int sePriceHt;
  final String coIdProfessional;
  final String coIdCustomer;
  final String? apId;
  final String? chgrId;
  final String? createdAt;
  final Map<String, dynamic>? professional;
  final Map<String, dynamic>? customer;
  final bool avatar;
  final dynamic reviewsPro;

  const SessionStartedEvent({
    required this.seId,
    required this.seStatus,
    required this.seType,
    required this.seRoom,
    required this.sePriceHt,
    required this.coIdProfessional,
    required this.coIdCustomer,
    this.apId,
    this.chgrId,
    this.createdAt,
    this.professional,
    this.customer,
    this.avatar = false,
    this.reviewsPro,
  });

  factory SessionStartedEvent.fromSession(Map<String, dynamic> session) {
    return SessionStartedEvent(
      seId: session['se_id']?.toString() ?? '',
      seStatus: session['se_status'] as String? ?? 'inprogress',
      seType: session['se_type'] as String? ?? 'video',
      seRoom: session['se_room'] as String? ?? '',
      sePriceHt: session['se_priceht'] as int? ?? 0,
      coIdProfessional: session['co_id_professional']?.toString() ?? '',
      coIdCustomer: session['co_id_customer']?.toString() ?? '',
      apId: session['ap_id']?.toString(),
      chgrId: session['chgr_id']?.toString(),
      createdAt: session['createdAt'] as String?,
      professional: session['professional'] as Map<String, dynamic>?,
      customer: session['customer'] as Map<String, dynamic>?,
      avatar: session['avatar'] as bool? ?? false,
      reviewsPro: session['reviewspro'],
    );
  }
}

/// Incoming call state model
class IncomingCall {
  final String? professionalId;
  final String? customerId;
  final String? professionalFullname;
  final String? customerFullname;
  final String type; // 'video', 'phone', 'chat'
  final String language;
  final String? tool;
  final int? appointmentId;
  final bool isProfessionalAI;
  final bool avatar;
  final String? recordingReplayOption;

  const IncomingCall({
    this.professionalId,
    this.customerId,
    this.professionalFullname,
    this.customerFullname,
    required this.type,
    required this.language,
    this.tool,
    this.appointmentId,
    this.isProfessionalAI = false,
    this.avatar = false,
    this.recordingReplayOption,
  });

  factory IncomingCall.fromCallParams(Map<String, dynamic> params) {
    return IncomingCall(
      professionalId: params['professionalId']?.toString(),
      customerId: params['customerId']?.toString(),
      professionalFullname: params['professionalFullname'] as String?,
      customerFullname: params['customerFullname'] as String?,
      type: params['type'] as String? ?? 'video',
      language: params['language'] as String? ?? 'fr',
      tool: params['tool'] as String?,
      appointmentId: params['appointmentId'] as int?,
      isProfessionalAI: params['isProfessionalAI'] as bool? ?? false,
      avatar: params['avatar'] as bool? ?? false,
      recordingReplayOption: params['recordingReplayOption'] as String?,
    );
  }

  Map<String, dynamic> toCallParams() => {
    'professionalId': professionalId,
    'customerId': customerId,
    'professionalFullname': professionalFullname,
    'customerFullname': customerFullname,
    'type': type,
    'language': language,
    if (tool != null) 'tool': tool,
    if (appointmentId != null) 'appointmentId': appointmentId,
    'isProfessionalAI': isProfessionalAI,
    'avatar': avatar,
    if (recordingReplayOption != null)
      'recordingReplayOption': recordingReplayOption,
  };
}

/// Incoming call notifier
class IncomingCallNotifier extends StateNotifier<IncomingCall?> {
  final WebSocketService _ws;

  IncomingCallNotifier(this._ws) : super(null) {
    _setupListeners();
  }

  void _setupListeners() {
    _ws.on('session_called', (event) {
      final callParams = event['callParams'] as Map<String, dynamic>? ?? {};
      state = IncomingCall.fromCallParams(callParams);
    });
  }

  void clear() {
    state = null;
  }
}

/// Session started event notifier
class SessionStartedNotifier extends StateNotifier<SessionStartedEvent?> {
  final WebSocketService _ws;

  SessionStartedNotifier(this._ws) : super(null) {
    _setupListeners();
  }

  void _setupListeners() {
    _ws.on('session_started', (event) {
      final session = event['session'] as Map<String, dynamic>? ?? {};
      state = SessionStartedEvent.fromSession(session);
    });
  }

  void clear() {
    state = null;
  }
}

/// Incoming call provider
final incomingCallProvider =
    StateNotifierProvider<IncomingCallNotifier, IncomingCall?>((ref) {
      final ws = ref.watch(webSocketServiceProvider);
      return IncomingCallNotifier(ws);
    });

/// Session started event provider
final sessionStartedProvider =
    StateNotifierProvider<SessionStartedNotifier, SessionStartedEvent?>((ref) {
      final ws = ref.watch(webSocketServiceProvider);
      return SessionStartedNotifier(ws);
    });
