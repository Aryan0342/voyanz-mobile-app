import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:voyanz/core/l10n/app_translations.dart';
import 'package:voyanz/core/network/websocket_service.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/providers/websocket_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
import 'package:voyanz/features/sessions/models/session_status.dart';
import 'package:voyanz/features/sessions/models/video_token.dart';
import 'package:voyanz/features/sessions/providers/sessions_provider.dart';

class VideoCallScreen extends ConsumerStatefulWidget {
  final String seId;
  final String coId;

  const VideoCallScreen({super.key, required this.seId, required this.coId});

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> {
  Timer? _heartbeatTimer;
  Timer? _elapsedTimer;
  late final Map<String, WebSocketEventHandler> _webSocketHandlers;
  late final String _connectionId;

  Duration _elapsed = Duration.zero;
  bool _sessionEndedHandled = false;
  bool _heartbeatActive = false;
  bool _leaving = false;
  bool _disposing = false;

  RtcEngine? _engine;
  bool _engineInitializing = false;
  bool _engineInitialized = false;
  bool _joined = false;
  int? _remoteUid;
  String? _channelId;

  bool _micEnabled = true;
  bool _cameraEnabled = true;
  ConnectionStateType? _connectionState;
  String? _connectionError;

  Future<bool> _ensureMediaPermissions() async {
    final statuses = await [Permission.microphone, Permission.camera].request();

    final mic = statuses[Permission.microphone];
    final cam = statuses[Permission.camera];

    final granted =
        mic == PermissionStatus.granted && cam == PermissionStatus.granted;
    if (granted) return true;

    final permanentlyDenied =
        mic == PermissionStatus.permanentlyDenied ||
        cam == PermissionStatus.permanentlyDenied;

    if (mounted) {
      setState(() {
        _connectionError = permanentlyDenied
            ? 'Camera/microphone permissions are permanently denied. Please enable them in app settings.'
            : 'Camera/microphone permissions are required to start video.';
      });
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    _connectionId =
        'mobile-${widget.seId}-${DateTime.now().microsecondsSinceEpoch}';
    _webSocketHandlers = {
      'session_aborted': _handleSessionEndEvent,
      'session_error': _handleSessionEndEvent,
      'session_videoaborted': _handleSessionEndEvent,
      'session_group_stopped': _handleSessionEndEvent,
      'session_group_all_clients_left': _handleSessionEndEvent,
      'participant_kicked': _handleParticipantKicked,
      'FORCE_MUTE_AUDIO': _handleForceMuteAudio,
      'FORCE_UNMUTE_AUDIO': _handleForceUnmuteAudio,
      'FORCE_DISABLE_VIDEO': _handleForceDisableVideo,
      'FORCE_ENABLE_VIDEO': _handleForceEnableVideo,
      'participant_muted': _handleParticipantMuted,
      'participant_video_disabled': _handleParticipantVideoDisabled,
      'sessions_updated': _handleSessionsUpdated,
    };
    _registerWebSocketHandlers();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      unawaited(() async {
        if (!mounted || !_heartbeatActive) return;
        try {
          await ref
              .read(sessionsRepositoryProvider)
              .sendHeartbeat(widget.seId, connectionId: _connectionId);
        } catch (_) {}
      }());
    });
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _disposing = true;
    _unregisterWebSocketHandlers();
    _heartbeatTimer?.cancel();
    _elapsedTimer?.cancel();
    unawaited(_disposeEngine());
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$m:$s';
    }
    return '$m:$s';
  }

  Future<void> _ensureAgoraJoined(VideoToken token) async {
    if (_joined || _engineInitializing) return;

    final hasPermissions = await _ensureMediaPermissions();
    if (!hasPermissions) return;

    if (!token.isAgora) {
      setState(() {
        _connectionError = 'provider:${token.provider}';
      });
      return;
    }
    if (token.appId == null || token.appId!.trim().isEmpty) {
      setState(() {
        _connectionError = 'missing-app-id';
      });
      return;
    }

    _engineInitializing = true;
    try {
      final engine = createAgoraRtcEngine();
      await engine.initialize(RtcEngineContext(appId: token.appId!.trim()));

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            if (!mounted) return;
            setState(() {
              _joined = true;
              _connectionState = ConnectionStateType.connectionStateConnected;
              _connectionError = null;
            });
            _heartbeatActive = true;
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            if (!mounted) return;
            setState(() {
              _remoteUid = remoteUid;
            });
          },
          onUserOffline: (connection, remoteUid, reason) {
            if (!mounted) return;
            if (_remoteUid == remoteUid) {
              setState(() {
                _remoteUid = null;
              });
            }
          },
          onConnectionStateChanged: (connection, state, reason) {
            if (!mounted) return;
            setState(() {
              _connectionState = state;
            });
          },
          onError: (err, msg) {
            if (!mounted) return;
            setState(() {
              _connectionError = msg.isEmpty ? err.name : msg;
            });
          },
        ),
      );

      await engine.enableAudio();
      await engine.enableVideo();
      await engine.muteLocalAudioStream(!_micEnabled);
      await engine.muteLocalVideoStream(!_cameraEnabled);
      await engine.startPreview();

      final room = token.room.trim();
      final uid = token.uid ?? 0;

      await engine.joinChannel(
        token: token.token,
        channelId: room,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      if (!mounted) {
        await engine.leaveChannel();
        await engine.release();
        return;
      }

      setState(() {
        _engine = engine;
        _engineInitialized = true;
        _channelId = room;
      });
    } catch (e) {
      if (mounted && !_disposing) {
        setState(() {
          _connectionError = e.toString();
        });
      }
    } finally {
      _engineInitializing = false;
    }
  }

  Future<void> _disposeEngine() async {
    _heartbeatActive = false;
    final engine = _engine;
    _engine = null;

    if (mounted && !_disposing) {
      setState(() {
        _engineInitialized = false;
        _joined = false;
        _remoteUid = null;
        _channelId = null;
      });
    }

    if (engine == null) return;
    try {
      await engine.leaveChannel();
    } catch (_) {}

    try {
      await engine.release();
    } catch (_) {}
  }

  Future<void> _toggleMic() async {
    await _setMicEnabled(!_micEnabled);
  }

  Future<void> _setMicEnabled(bool enabled) async {
    final engine = _engine;
    if (engine == null) {
      if (mounted) {
        setState(() {
          _micEnabled = enabled;
        });
      }
      return;
    }

    await engine.muteLocalAudioStream(!enabled);
    if (!mounted) return;
    setState(() {
      _micEnabled = enabled;
    });
  }

  Future<void> _toggleCamera() async {
    await _setCameraEnabled(!_cameraEnabled);
  }

  Future<void> _setCameraEnabled(bool enabled) async {
    final engine = _engine;
    if (engine == null) {
      if (mounted) {
        setState(() {
          _cameraEnabled = enabled;
        });
      }
      return;
    }

    await engine.muteLocalVideoStream(!enabled);
    if (!mounted) return;
    setState(() {
      _cameraEnabled = enabled;
    });
  }

  Future<void> _endCallAndExit({bool notifyServer = true}) async {
    if (_leaving) return;
    _leaving = true;

    if (notifyServer) {
      _sessionEndedHandled = true;
      final currentUser = ref.read(authStateProvider).valueOrNull;
      final otherCoId = widget.coId.trim();
      if (otherCoId.isNotEmpty && otherCoId != currentUser?.coId.trim()) {
        ref.read(webSocketServiceProvider).send('session_videoaborted', {
          'co_id': otherCoId,
          'who': currentUser?.isProfessional == true
              ? 'professional'
              : 'customer',
        });
      }

      ref.read(webSocketServiceProvider).send('session_stop', {
        'se_id': widget.seId,
      });
    }

    await _disposeEngine();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _registerWebSocketHandlers() {
    final ws = ref.read(webSocketServiceProvider);
    for (final entry in _webSocketHandlers.entries) {
      ws.on(entry.key, entry.value);
    }
  }

  void _unregisterWebSocketHandlers() {
    final ws = ref.read(webSocketServiceProvider);
    for (final entry in _webSocketHandlers.entries) {
      ws.off(entry.key, entry.value);
    }
  }

  void _handleSessionEndEvent(Map<String, dynamic> event) {
    final action = event['action']?.toString() ?? '';
    final allowNoSessionId = action == 'session_videoaborted';
    if (!_matchesCurrentSession(event, allowNoSessionId: allowNoSessionId)) {
      return;
    }

    _finishFromServer(_messageForSessionEnd(action));
  }

  void _handleParticipantKicked(Map<String, dynamic> event) {
    if (!_targetsCurrentUser(event)) return;
    if (!_matchesCurrentSession(event, allowNoSessionId: true)) return;

    _finishFromServer('You were removed from the session.');
  }

  void _handleForceMuteAudio(Map<String, dynamic> event) {
    if (!_matchesCurrentSession(event, allowNoSessionId: true)) return;
    unawaited(_setMicEnabled(false));
  }

  void _handleForceUnmuteAudio(Map<String, dynamic> event) {
    if (!_matchesCurrentSession(event, allowNoSessionId: true)) return;
    unawaited(_setMicEnabled(true));
  }

  void _handleForceDisableVideo(Map<String, dynamic> event) {
    if (!_matchesCurrentSession(event, allowNoSessionId: true)) return;
    unawaited(_setCameraEnabled(false));
  }

  void _handleForceEnableVideo(Map<String, dynamic> event) {
    if (!_matchesCurrentSession(event, allowNoSessionId: true)) return;
    unawaited(_setCameraEnabled(true));
  }

  void _handleParticipantMuted(Map<String, dynamic> event) {
    if (!_hasTargetIds(event)) return;
    if (!_targetsCurrentUser(event)) return;
    final muted = _readBoolFromEvent(event, const [
      'muted',
      'isMuted',
      'audioMuted',
    ]);
    unawaited(_setMicEnabled(!(muted ?? true)));
  }

  void _handleParticipantVideoDisabled(Map<String, dynamic> event) {
    if (!_hasTargetIds(event)) return;
    if (!_targetsCurrentUser(event)) return;
    final disabled = _readBoolFromEvent(event, const [
      'disabled',
      'isDisabled',
      'videoDisabled',
    ]);
    unawaited(_setCameraEnabled(!(disabled ?? true)));
  }

  void _handleSessionsUpdated(Map<String, dynamic> event) {
    if (!_matchesCurrentSession(event, allowNoSessionId: true)) return;
    ref.invalidate(sessionStatusProvider(widget.seId));
    ref.invalidate(sessionStatusLivePollingProvider(widget.seId));
  }

  void _finishFromServer(String message) {
    if (!mounted || _sessionEndedHandled) return;
    _sessionEndedHandled = true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Future<void>.delayed(const Duration(milliseconds: 400), () {
      unawaited(_endCallAndExit(notifyServer: false));
    });
  }

  String _messageForSessionEnd(String action) {
    switch (action) {
      case 'session_videoaborted':
        return 'The other participant ended the call.';
      case 'session_group_stopped':
      case 'session_group_all_clients_left':
        return 'The group session has ended.';
      case 'session_error':
        return 'The session ended because of a server error.';
      case 'session_aborted':
        return 'The session was cancelled.';
      default:
        return 'The session has ended.';
    }
  }

  bool _matchesCurrentSession(
    Map<String, dynamic> event, {
    required bool allowNoSessionId,
  }) {
    final ids = <String>{};
    _collectSessionIds(event, ids);

    if (ids.isEmpty) return allowNoSessionId;
    return ids.contains(widget.seId);
  }

  void _collectSessionIds(dynamic source, Set<String> ids) {
    if (source is Map) {
      for (final key in const ['se_id', 'session_id', 'sessionId']) {
        _addNonEmpty(ids, source[key]);
      }

      final session = source['session'];
      if (session is Map) {
        _collectSessionIds(session, ids);
        _addNonEmpty(ids, session['id']);
      }

      final data = source['data'];
      if (data is Map) {
        _collectSessionIds(data, ids);
      }

      final dataSessions = data is Map ? data['sessions'] : null;
      final sessions = source['sessions'] ?? dataSessions;
      if (sessions is List) {
        for (final session in sessions) {
          _collectSessionIds(session, ids);
          if (session is Map) {
            _addNonEmpty(ids, session['id']);
          }
        }
      }
    }
  }

  bool _targetsCurrentUser(Map<String, dynamic> event) {
    final currentCoId = ref.read(authStateProvider).valueOrNull?.coId.trim();
    if (currentCoId == null || currentCoId.isEmpty) return true;

    final targets = <String>{};
    _collectTargetIds(event, targets);
    if (targets.isEmpty) return true;
    return targets.contains(currentCoId);
  }

  bool _hasTargetIds(Map<String, dynamic> event) {
    final targets = <String>{};
    _collectTargetIds(event, targets);
    return targets.isNotEmpty;
  }

  void _collectTargetIds(dynamic source, Set<String> ids) {
    if (source is! Map) return;

    for (final key in const [
      'co_id',
      'coId',
      'participantCoId',
      'participant_co_id',
      'targetCoId',
      'target_co_id',
      'customerId',
      'professionalId',
    ]) {
      _addNonEmpty(ids, source[key]);
    }

    final data = source['data'];
    if (data is Map) _collectTargetIds(data, ids);

    final participant = source['participant'];
    if (participant is Map) _collectTargetIds(participant, ids);
  }

  bool? _readBoolFromEvent(Map<String, dynamic> event, List<String> keys) {
    dynamic readFrom(dynamic source) {
      if (source is! Map) return null;
      for (final key in keys) {
        if (source.containsKey(key)) return source[key];
      }
      return null;
    }

    final raw =
        readFrom(event) ??
        readFrom(event['data']) ??
        readFrom(event['participant']);

    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    final text = raw?.toString().trim().toLowerCase();
    if (text == null || text.isEmpty) return null;
    if (text == 'true' || text == '1' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'no') return false;
    return null;
  }

  void _addNonEmpty(Set<String> values, dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return;
    values.add(text);
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final currentUserCoId = ref.watch(authStateProvider).valueOrNull?.coId;
    final isProfessional =
        ref.watch(authStateProvider).valueOrNull?.isProfessional ?? false;

    final videoCoId =
        currentUserCoId != null && currentUserCoId.trim().isNotEmpty
        ? currentUserCoId.trim()
        : widget.coId;

    final tokenAsync = ref.watch(
      videoTokenProvider((
        seId: widget.seId,
        coId: videoCoId,
        connectionId: _connectionId,
      )),
    );
    final liveStatusAsync = ref.watch(
      sessionStatusLivePollingProvider(widget.seId),
    );
    final localEngine = _engine;

    ref.listen<AsyncValue<VideoToken>>(
      videoTokenProvider((
        seId: widget.seId,
        coId: videoCoId,
        connectionId: _connectionId,
      )),
      (_, next) {
        next.whenData((token) {
          unawaited(_ensureAgoraJoined(token));
        });
      },
    );

    ref.listen<AsyncValue<SessionStatus>>(
      sessionStatusLivePollingProvider(widget.seId),
      (_, next) {
        next.whenData((status) {
          if (!mounted || _sessionEndedHandled || !status.isTerminal) return;
          _sessionEndedHandled = true;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                status.localizedMessage(t, isProfessional: isProfessional),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );

          Future<void>.delayed(const Duration(milliseconds: 400), () {
            unawaited(_endCallAndExit(notifyServer: false));
          });
        });
      },
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.hero),
        child: SafeArea(
          child: tokenAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.mediumPurple),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 56,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.connectionError,
                      style: GoogleFonts.jost(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.toString(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(t.goBack),
                    ),
                  ],
                ),
              ),
            ),
            data: (token) {
              if (!token.isAgora) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      t.videoProviderNotSupported,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        color: AppColors.error,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                          onPressed: () {
                            unawaited(_endCallAndExit());
                          },
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDuration(_elapsed),
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  _SessionStatusBanner(
                    statusAsync: liveStatusAsync,
                    t: t,
                    isProfessional: isProfessional,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildRemoteView(t),
                            if (_engineInitialized && localEngine != null)
                              Positioned(
                                right: 12,
                                top: 12,
                                width: 120,
                                height: 170,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: _cameraEnabled
                                        ? AgoraVideoView(
                                            controller: VideoViewController(
                                              rtcEngine: localEngine,
                                              canvas: const VideoCanvas(uid: 0),
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              t.localPreview,
                                              style: GoogleFonts.montserrat(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            Positioned(
                              left: 14,
                              bottom: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  t.providerLabel(token.provider),
                                  style: GoogleFonts.montserrat(
                                    fontSize: 11,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ControlButton(
                          icon: _micEnabled ? Icons.mic : Icons.mic_off,
                          label: _micEnabled ? t.mute : t.unmute,
                          onTap: _toggleMic,
                        ),
                        GestureDetector(
                          onTap: () {
                            unawaited(_endCallAndExit());
                          },
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.error,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.error.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.call_end,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                        _ControlButton(
                          icon: _cameraEnabled
                              ? Icons.videocam
                              : Icons.videocam_off,
                          label: _cameraEnabled ? t.cameraOff : t.camera,
                          onTap: _toggleCamera,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRemoteView(AppTranslations t) {
    final isConnecting = !_joined || _engineInitializing;
    final isReconnecting =
        _connectionState == ConnectionStateType.connectionStateReconnecting;

    if (_connectionError != null && _connectionError!.isNotEmpty) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              _connectionError!,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
      );
    }

    final engine = _engine;
    if (_remoteUid != null && engine != null && _channelId != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: _channelId!),
        ),
      );
    }

    final message = isConnecting
        ? t.connectingVideo
        : isReconnecting
        ? t.reconnectingVideo
        : t.waitingRemoteParticipant;

    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.rosePink,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionStatusBanner extends StatelessWidget {
  final AsyncValue<SessionStatus> statusAsync;
  final AppTranslations t;
  final bool isProfessional;

  const _SessionStatusBanner({
    required this.statusAsync,
    required this.t,
    required this.isProfessional,
  });

  @override
  Widget build(BuildContext context) {
    return statusAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (status) {
        final isGood = status.isInProgress;
        final color = isGood ? AppColors.success : AppColors.mediumPurple;
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${status.localizedLabel(t)}: ${status.localizedMessage(t, isProfessional: isProfessional)}',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceCard.withValues(alpha: 0.8),
              border: Border.all(
                color: AppColors.mediumPurple.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
