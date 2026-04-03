import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/features/sessions/models/session_status.dart';
import 'package:voyanz/features/sessions/providers/sessions_provider.dart';

class SessionWaitingScreen extends ConsumerStatefulWidget {
  final String seId;
  final String coId;
  final String type;

  const SessionWaitingScreen({
    super.key,
    required this.seId,
    required this.coId,
    required this.type,
  });

  @override
  ConsumerState<SessionWaitingScreen> createState() =>
      _SessionWaitingScreenState();
}

class _SessionWaitingScreenState extends ConsumerState<SessionWaitingScreen> {
  static const Duration _waitTimeout = Duration(minutes: 3);
  bool _hasNavigated = false;
  late final DateTime _enteredAt;

  @override
  void initState() {
    super.initState();
    _enteredAt = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(sessionStatusPollingProvider(widget.seId));

    ref.listen<AsyncValue<SessionStatus>>(
      sessionStatusPollingProvider(widget.seId),
      (previous, next) {
        next.whenData((status) {
          if (!mounted || _hasNavigated || !status.isActive) return;

          _hasNavigated = true;
          _navigateToSession(context);
        });
      },
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.hero),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: statusAsync.when(
              loading: _buildLoading,
              error: (e, _) => _buildError(context, e.toString()),
              data: (status) => _buildStatus(context, status),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.rosePink),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 56),
          const SizedBox(height: 14),
          Text(
            'Unable to check session status',
            textAlign: TextAlign.center,
            style: GoogleFonts.jost(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () =>
                ref.invalidate(sessionStatusPollingProvider(widget.seId)),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatus(BuildContext context, SessionStatus status) {
    final isWaiting = status.isWaiting;
    final hasTimedOut =
        isWaiting && DateTime.now().difference(_enteredAt) >= _waitTimeout;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isWaiting
                    ? AppColors.mediumPurple.withValues(alpha: 0.2)
                    : AppColors.error.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status.uiLabel,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700,
                  color: isWaiting ? AppColors.mediumPurple : AppColors.error,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          width: 120,
          height: 120,
          margin: const EdgeInsets.symmetric(horizontal: 100),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.accent,
          ),
          child: Icon(
            isWaiting ? Icons.hourglass_top_rounded : Icons.event_busy_outlined,
            color: Colors.white,
            size: 52,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          isWaiting
              ? 'Waiting for professional to join'
              : 'Session unavailable',
          textAlign: TextAlign.center,
          style: GoogleFonts.jost(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasTimedOut
              ? 'This is taking longer than expected. You can retry now or create a new session request.'
              : status.uiMessage,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(color: AppColors.textSecondary),
        ),
        const Spacer(),
        if (isWaiting && !hasTimedOut)
          OutlinedButton.icon(
            onPressed: () =>
                ref.invalidate(sessionStatusPollingProvider(widget.seId)),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh now'),
          ),
        if (isWaiting && hasTimedOut) ...[
          ElevatedButton.icon(
            onPressed: _rebookSession,
            icon: const Icon(Icons.replay_outlined),
            label: const Text('Rebook session'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () =>
                ref.invalidate(sessionStatusPollingProvider(widget.seId)),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry status check'),
          ),
        ],
        if (!isWaiting)
          ElevatedButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.home_outlined),
            label: const Text('Back to home'),
          ),
      ],
    );
  }

  void _navigateToSession(BuildContext context) {
    if (widget.type == 'video') {
      context.pushReplacement('/video/${widget.seId}/${widget.coId}');
      return;
    }

    if (widget.type == 'phone') {
      context.pushReplacement('/session/phone/${widget.seId}/${widget.coId}');
      return;
    }

    if (widget.type == 'chat') {
      context.pushReplacement('/session/chat/${widget.seId}/${widget.coId}');
      return;
    }

    context.pushReplacement('/home');
  }

  Future<void> _rebookSession() async {
    try {
      final newSeId = await ref
          .read(sessionsRepositoryProvider)
          .createSessionCall(typeCall: widget.type, coId: widget.coId);
      if (!mounted) return;
      context.pushReplacement(
        '/session/wait/${widget.type}/$newSeId/${widget.coId}',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not create a new session request. Please try again.',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
