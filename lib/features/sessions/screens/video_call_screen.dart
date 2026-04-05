import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/l10n/app_translations.dart';
import 'package:voyanz/core/providers/language_provider.dart';
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

  Duration _elapsed = Duration.zero;
  bool _sessionEndedHandled = false;

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

  @override
  void initState() {
    super.initState();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.read(sessionsRepositoryProvider).sendHeartbeat(widget.seId);
    });
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
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
      setState(() {
        _connectionError = e.toString();
      });
    } finally {
      _engineInitializing = false;
    }
  }

  Future<void> _disposeEngine() async {
    final engine = _engine;
    _engine = null;

    if (engine == null) return;
    try {
      await engine.leaveChannel();
    } catch (_) {}

    try {
      await engine.release();
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _engineInitialized = false;
      _joined = false;
      _remoteUid = null;
      _channelId = null;
    });
  }

  Future<void> _toggleMic() async {
    final engine = _engine;
    if (engine == null) return;

    final next = !_micEnabled;
    await engine.muteLocalAudioStream(!next);
    if (!mounted) return;
    setState(() {
      _micEnabled = next;
    });
  }

  Future<void> _toggleCamera() async {
    final engine = _engine;
    if (engine == null) return;

    final next = !_cameraEnabled;
    await engine.muteLocalVideoStream(!next);
    if (!mounted) return;
    setState(() {
      _cameraEnabled = next;
    });
  }

  Future<void> _endCallAndExit() async {
    await _disposeEngine();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final isProfessional =
        ref.watch(authStateProvider).valueOrNull?.isProfessional ?? false;

    final tokenAsync = ref.watch(
      videoTokenProvider((seId: widget.seId, coId: widget.coId)),
    );
    final liveStatusAsync = ref.watch(
      sessionStatusLivePollingProvider(widget.seId),
    );

    ref.listen<AsyncValue<VideoToken>>(
      videoTokenProvider((seId: widget.seId, coId: widget.coId)),
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
            unawaited(_endCallAndExit());
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
              child: CircularProgressIndicator(color: AppColors.rosePink),
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
                            if (_engineInitialized)
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
                                              rtcEngine: _engine!,
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
                                  borderRadius: BorderRadius.circular(10),
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

    if (_remoteUid != null && _engine != null && _channelId != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine!,
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
            borderRadius: BorderRadius.circular(10),
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
