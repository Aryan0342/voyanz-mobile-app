import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/features/sessions/providers/sessions_provider.dart';

/// Placeholder video-call screen.
///
/// When Agora SDK integration is finalized, this screen will initialize
/// the Agora engine with `appId`, `token`, `channelName` (room), and `uid`
/// from the [VideoToken] returned by the API.
class VideoCallScreen extends ConsumerStatefulWidget {
  final String seId;
  final String coId;

  const VideoCallScreen({super.key, required this.seId, required this.coId});

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> {
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    // Send heartbeat every 30s to keep session alive.
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.read(sessionsRepositoryProvider).sendHeartbeat(widget.seId);
    });
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokenAsync = ref.watch(
      videoTokenProvider((seId: widget.seId, coId: widget.coId)),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Video Call'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: tokenAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.white)),
        ),
        data: (token) {
          // TODO: Initialize Agora RTC engine here:
          //   RtcEngine.createWithContext(RtcEngineContext(token.appId!))
          //   ..joinChannel(token.token, token.room, null, token.uid ?? 0)
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam, color: Colors.white, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Connected to ${token.room}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  'Provider: ${token.provider}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 32),
                FilledButton.tonalIcon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.call_end, color: Colors.red),
                  label: const Text('End Call'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
