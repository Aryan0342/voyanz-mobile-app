import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/l10n/app_translations.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/providers/websocket_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
import 'package:voyanz/features/sessions/data/sessions_data_source.dart';
import 'package:voyanz/features/sessions/models/session_type.dart';
import 'package:voyanz/features/sessions/models/session_status.dart';
import 'package:voyanz/features/sessions/navigation/session_navigation.dart';
import 'package:voyanz/features/sessions/providers/sessions_provider.dart';
import 'package:voyanz/features/wallet/providers/wallet_provider.dart';

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
    final t = ref.watch(translationsProvider);
    final isProfessional =
        ref.watch(authStateProvider).valueOrNull?.isProfessional ?? false;
    // Use the live polling provider (continues until terminal) so a freshly
    // created video session keeps updating while we wait for the professional
    // to actually join.
    final statusAsync = ref.watch(sessionStatusLivePollingProvider(widget.seId));

    ref.listen<AsyncValue<SessionStatus>>(
      sessionStatusLivePollingProvider(widget.seId),
      (previous, next) {
        next.whenOrNull(
          error: (error, _) async {
            if (error is SessionAuthExpiredException) {
              if (!mounted) return;
              final t = ref.read(translationsProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(t.errorMessage(error.toString())),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              await ref.read(authStateProvider.notifier).logout();
              if (!mounted) return;
              context.go('/login');
            }
          },
        );
        next.whenData((status) {
          if (!mounted || _hasNavigated) return;
          if (!status.isActive) return;

          final resolvedType =
              normalizeSessionType(status.sessionType) ??
              normalizeSessionType(widget.type);
          final isVideo = resolvedType == 'video';

          // Bug #2: for video, only advance to the call screen once the
          // professional is actually present. A REST-created session is
          // `inprogress` immediately even though nobody has joined yet.
          if (isVideo && !status.isProfessionalPresent) return;

          _hasNavigated = true;
          _navigateToSession(context, status: status);
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
              error: (e, _) => _buildError(context, 'An error occurred. Please try again.', t),
              data: (status) =>
                  _buildStatus(context, status, t, isProfessional),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.mediumPurple),
    );
  }

  Widget _buildError(BuildContext context, String message, AppTranslations t) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 56),
          const SizedBox(height: 14),
          Text(
            t.unableCheckSessionStatus,
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
                ref.invalidate(sessionStatusLivePollingProvider(widget.seId)),
            icon: const Icon(Icons.refresh),
            label: Text(t.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildStatus(
    BuildContext context,
    SessionStatus status,
    AppTranslations t,
    bool isProfessional,
  ) {
    // Bug #2: an `inprogress` video session whose professional has NOT joined
    // yet must be presented as "waiting", not as "session is live / connected".
    final resolvedType =
        normalizeSessionType(status.sessionType) ??
        normalizeSessionType(widget.type);
    final waitingForPro =
        resolvedType == 'video' &&
        status.isInProgress &&
        !status.isProfessionalPresent;
    final isWaiting = status.isWaiting || waitingForPro;
    final hasTimedOut =
        isWaiting && DateTime.now().difference(_enteredAt) >= _waitTimeout;
    final elapsed = DateTime.now().difference(_enteredAt);
    final elapsedText =
        '${elapsed.inMinutes}:${elapsed.inSeconds.remainder(60).toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RevealIn(
          delayMs: 20,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: _endSessionAndLeave,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isWaiting
                      ? AppColors.mediumPurple.withValues(alpha: 0.11)
                      : AppColors.error.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isWaiting
                        ? AppColors.mediumPurple.withValues(alpha: 0.24)
                        : AppColors.error.withValues(alpha: 0.24),
                  ),
                ),
                child: Text(
                  status.localizedLabel(t),
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                    color: isWaiting ? AppColors.mediumPurple : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _RevealIn(
          delayMs: 70,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MetaStat(
                    label: t.session,
                    value: '#${widget.seId}',
                    icon: Icons.badge_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetaStat(
                    label: t.sessionStatusPendingLabel,
                    value: elapsedText,
                    icon: Icons.timer_outlined,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        _RevealIn(
          delayMs: 120,
          child: Container(
            width: 120,
            height: 120,
            margin: const EdgeInsets.symmetric(horizontal: 100),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              gradient: AppGradients.accent,
            ),
            child: Icon(
              isWaiting
                  ? Icons.hourglass_top_rounded
                  : Icons.event_busy_outlined,
              color: Colors.white,
              size: 52,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          isWaiting
              ? t.waitingForJoinTitle(isProfessional: isProfessional)
              : t.sessionUnavailable,
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
              ? t.sessionWaitTimedOutMessage
              : waitingForPro
              ? t.waitingForJoinTitle(isProfessional: isProfessional)
              : status.localizedMessage(t, isProfessional: isProfessional),
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(color: AppColors.textSecondary),
        ),
        const Spacer(),
        if (isWaiting && !hasTimedOut) ...[
          OutlinedButton.icon(
            onPressed: () =>
                ref.invalidate(sessionStatusLivePollingProvider(widget.seId)),
            icon: const Icon(Icons.refresh),
            label: Text(t.refreshNow),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _endSessionAndLeave,
            icon: const Icon(Icons.call_end_outlined),
            label: Text(t.endSession),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
          ),
        ],
        if (isWaiting && hasTimedOut) ...[
          ElevatedButton.icon(
            onPressed: _rebookSession,
            icon: const Icon(Icons.replay_outlined),
            label: Text(t.rebookSession),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () =>
                ref.invalidate(sessionStatusLivePollingProvider(widget.seId)),
            icon: const Icon(Icons.refresh),
            label: Text(t.retryStatusCheck),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _endSessionAndLeave,
            icon: const Icon(Icons.call_end_outlined),
            label: Text(t.endSession),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
          ),
        ],
        if (!isWaiting)
          ElevatedButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.home_outlined),
            label: Text(t.backToHome),
          ),
      ],
    );
  }

  void _navigateToSession(BuildContext context, {SessionStatus? status}) {
    final resolvedType =
        normalizeSessionType(status?.sessionType) ??
        normalizeSessionType(widget.type);

    if (resolvedType == null) {
      context.pushReplacement('/home');
      return;
    }

    openSessionRoute(
      context,
      type: resolvedType,
      seId: status?.seId ?? widget.seId,
      coId: widget.coId,
      chgrId: status?.chgrId,
      replace: true,
    );
  }

  /// Terminates the current session server-side and leaves the waiting screen.
  ///
  /// A REST-created session stays `inprogress` forever if the professional never
  /// joins, blocking new launches with `409 SESSION_ALREADY_LAUNCHED` (and being
  /// billed for the wait if the backend ever finalizes it). Leaving the screen
  /// must therefore explicitly close the session.
  Future<void> _endSessionAndLeave() async {
    final t = ref.read(translationsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          t.endSessionConfirmTitle,
          style: GoogleFonts.jost(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          t.endSessionConfirmMessage,
          style: GoogleFonts.montserrat(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              t.cancel,
              style: GoogleFonts.montserrat(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              t.endSession,
              style: GoogleFonts.montserrat(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ws = ref.read(webSocketServiceProvider);
    if (!ws.isConnected) {
      await ws.connect();
    }
    final currentUser = ref.read(authStateProvider).valueOrNull;
    final resolvedType = normalizeSessionType(widget.type);
    if (resolvedType == 'video') {
      ws.send('session_videoaborted', {
        'co_id': widget.coId,
        'who': currentUser?.isProfessional == true
            ? 'professional'
            : 'customer',
      });
    }
    ws.send('session_stop', {'se_id': widget.seId});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.sessionEnded),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    if (mounted) {
      context.go('/home');
    }
  }

  Future<void> _rebookSession() async {
    try {
      final resolvedType = normalizeSessionType(widget.type);
      if (resolvedType == null) {
        if (!mounted) return;
        final t = ref.read(translationsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.chooseSessionType),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Close the stale `inprogress` session first so the rebook does not hit
      // `409 SESSION_ALREADY_LAUNCHED`.
      final ws = ref.read(webSocketServiceProvider);
      if (!ws.isConnected) {
        await ws.connect();
      }
      ws.send('session_stop', {'se_id': widget.seId});
      await Future<void>.delayed(const Duration(milliseconds: 1200));

      // Pre-session balance gate (POST /web/1.0/check-balance).
      // If the check itself fails, fall through and let the server gate the call.
      try {
        final balance = await ref
            .read(walletRepositoryProvider)
            .checkBalance(professionalId: widget.coId, type: resolvedType);
        if (!mounted) return;
        if (balance.isInsufficient ||
            (!balance.success && balance.error != null)) {
          _showInsufficientBalanceDialog();
          return;
        }
      } catch (_) {
        // Balance service unreachable — proceed; server still enforces on /call.
      }

      final launch = await ref
          .read(sessionsRepositoryProvider)
          .createSessionCall(typeCall: resolvedType, coId: widget.coId);
      if (!mounted) return;
      openLaunchResult(
        context,
        launch,
        fallbackType: resolvedType,
        coId: widget.coId,
        replace: true,
      );
    } on SessionAuthExpiredException catch (e) {
      if (!mounted) return;
      final t = ref.read(translationsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('An error occurred. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await ref.read(authStateProvider.notifier).logout();
      if (!mounted) return;
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      final t = ref.read(translationsProvider);
      if (e.toString().toLowerCase().contains('insufficient_balance')) {
        _showInsufficientBalanceDialog();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.rebookSessionFailed),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showInsufficientBalanceDialog() {
    final t = ref.read(translationsProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          t.insufficientBalance,
          style: GoogleFonts.jost(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          t.topUpNow,
          style: GoogleFonts.montserrat(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              t.cancel,
              style: GoogleFonts.montserrat(color: AppColors.textMuted),
            ),
          ),
          GradientButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/wallet/topup');
            },
            child: Text(t.topUpNow),
          ),
        ],
      ),
    );
  }
}

class _MetaStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetaStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 16),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.jost(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _RevealIn extends StatelessWidget {
  final Widget child;
  final int delayMs;

  const _RevealIn({required this.child, this.delayMs = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, builtChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: builtChild,
          ),
        );
      },
      child: child,
    );
  }
}
