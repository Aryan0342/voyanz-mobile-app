import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/l10n/app_translations.dart';
import 'package:voyanz/core/network/websocket_service.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/providers/websocket_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
import 'package:voyanz/features/sessions/data/sessions_data_source.dart';
import 'package:voyanz/features/sessions/models/session_status.dart';
import 'package:voyanz/features/sessions/providers/sessions_provider.dart';
import 'package:voyanz/features/wallet/providers/wallet_provider.dart';

class PhoneSessionScreen extends ConsumerStatefulWidget {
  final String seId;
  final String coId;

  const PhoneSessionScreen({super.key, required this.seId, required this.coId});

  @override
  ConsumerState<PhoneSessionScreen> createState() => _PhoneSessionScreenState();
}

class _PhoneSessionScreenState extends ConsumerState<PhoneSessionScreen> {
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  bool _sessionEndedHandled = false;
  WebSocketService? _webSocketService;
  bool _wsHandlersRegistered = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsed += const Duration(seconds: 1));
      }
    });
    final ws = ref.read(webSocketServiceProvider);
    _webSocketService = ws;
    _registerWebSocketHandlers(ws);
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_wsHandlersRegistered) {
      final ws = _webSocketService;
      if (ws != null) {
        ws.off('session_error', _handleSessionError);
        ws.off('session_aborted', _handleSessionAborted);
        ws.off('session_stop', _handleSessionEndEvent);
        ws.off('session_videoaborted', _handleSessionEndEvent);
        ws.off('sessions_updated', _handleSessionsUpdated);
      }
    }
    super.dispose();
  }

  void _registerWebSocketHandlers(WebSocketService ws) {
    ws.on('session_error', _handleSessionError);
    ws.on('session_aborted', _handleSessionAborted);
    ws.on('session_stop', _handleSessionEndEvent);
    ws.on('session_videoaborted', _handleSessionEndEvent);
    ws.on('sessions_updated', _handleSessionsUpdated);
    _wsHandlersRegistered = true;
  }

  void _handleSessionError(Map<String, dynamic> event) {
    final errorCode = (event['errorCode']?.toString() ?? '').toLowerCase();
    final error = event['error']?.toString() ?? '';
    if (errorCode.contains('no_star') ||
        errorCode.contains('star_confirm') ||
        error.contains('no_star') ||
        error.contains('star_confirm')) {
      _endSessionWithMessage(
        ref.read(translationsProvider).sessionStatusNoStarConfirmMessage,
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.isEmpty ? 'Session error' : error),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleSessionAborted(Map<String, dynamic> event) {
    final infos = event['infos'];
    final reason = infos is Map<String, dynamic>
        ? (infos['reason']?.toString() ?? '')
        : (event['reason']?.toString() ?? '');
    _endSessionWithMessage(_endReasonMessage(reason));
  }

  String _endReasonMessage(String reason) {
    final t = ref.read(translationsProvider);
    switch (reason.toLowerCase()) {
      case 'professional_no_star_confirm':
      case 'no_star_confirm':
        return t.sessionStatusNoStarConfirmMessage;
      case 'professional_unavailable':
        return t.phoneEndReasonProfessionalUnavailable;
      case 'customer_no_answer':
        return t.phoneEndReasonCustomerNoAnswer;
      default:
        return t.sessionStatusCanceledMessage;
    }
  }

  /// The professional side has no dedicated abort event for phone end-reasons;
  /// `sessions_updated` is the real-time trigger. Refetch the authoritative
  /// session status so a terminal `rejected` state closes the screen quickly.
  void _handleSessionsUpdated(Map<String, dynamic> event) {
    if (!mounted) return;
    ref.invalidate(sessionStatusLivePollingProvider(widget.seId));
  }

  void _handleSessionEndEvent(Map<String, dynamic> event) {
    _endSessionWithMessage(
      ref.read(translationsProvider).sessionStatusCompletedMessage,
    );
  }

  void _endSessionWithMessage(String message) {
    if (!mounted || _sessionEndedHandled) return;
    _sessionEndedHandled = true;
    // PAYMENT Q12: billing is computed when the session closes, so the
    // wallet must be refreshed after completion.
    ref.invalidate(walletLiveBalanceProvider);
    ref.invalidate(walletHistoryProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      Navigator.of(context).pop();
    });
  }

  /// Terminates the current phone session server-side and leaves the screen.
  ///
  /// A REST-created phone session stays `inprogress` until the backend receives
  /// `session_stop` (or the Twilio call ends). Leaving the screen without
  /// stopping it leaves a ghost session blocking new calls with
  /// `409 SESSION_ALREADY_LAUNCHED`.
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

    _sessionEndedHandled = true;
    final ws = ref.read(webSocketServiceProvider);
    if (!ws.isConnected) {
      await ws.connect();
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

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$m:$s';
    }
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final isProfessional =
        ref.watch(authStateProvider).valueOrNull?.isProfessional ?? false;
    final liveStatusAsync = ref.watch(
      sessionStatusLivePollingProvider(widget.seId),
    );

    ref.listen<AsyncValue<SessionStatus>>(
      sessionStatusLivePollingProvider(widget.seId),
      (_, next) {
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
            if (!mounted) return;
            Navigator.of(context).pop();
          });
        });
      },
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.hero),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: Column(
              children: [
                Row(
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
                        color: AppColors.success.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Text(
                        _formatDuration(_elapsed),
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700,
                          color: AppColors.online,
                        ),
                      ),
                    ),
                  ],
                ),
                _SessionStatusBanner(
                  statusAsync: liveStatusAsync,
                  t: t,
                  isProfessional: isProfessional,
                ),
                if (isProfessional) ...[
                  const SizedBox(height: 12),
                  _ProConfirmBanner(
                    confirmed:
                        liveStatusAsync.valueOrNull?.isActive ?? false,
                    remaining: (55 - _elapsed.inSeconds).clamp(0, 55),
                    t: t,
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SessionMeta(
                          label: t.session,
                          value: '#${widget.seId}',
                          icon: Icons.badge_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SessionMeta(
                          label: t.sessionStatusInProgressLabel,
                          value: _formatDuration(_elapsed),
                          icon: Icons.timer_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    gradient: AppGradients.accent,
                  ),
                  child: const Icon(
                    Icons.phone_in_talk,
                    color: Colors.white,
                    size: 52,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  t.answerPhoneTitle,
                  style: GoogleFonts.jost(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t.phonePstnSessionMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  t.phonePstnNoInAppAudio,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(color: AppColors.textMuted),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _endSessionAndLeave,
                    icon: const Icon(Icons.call_end_outlined),
                    label: Text(
                      t.endSession,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    onPressed: () => context.go('/home'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.home_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          t.backToHome,
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionMeta extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SessionMeta({
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
          Icon(icon, size: 16, color: AppColors.textSecondary),
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

class _ProConfirmBanner extends StatelessWidget {
  final bool confirmed;
  final int remaining;
  final AppTranslations t;

  const _ProConfirmBanner({
    required this.confirmed,
    required this.remaining,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    final String title;
    final String? subtitle;

    if (confirmed) {
      color = AppColors.success;
      icon = Icons.check_circle_outline;
      title = t.phonePstnCallConfirmed;
      subtitle = null;
    } else if (remaining <= 0) {
      color = AppColors.error;
      icon = Icons.timer_off_outlined;
      title = t.sessionStatusNoStarConfirmLabel;
      subtitle = t.sessionStatusNoStarConfirmMessage;
    } else {
      color = AppColors.warning;
      icon = Icons.phone_in_talk_outlined;
      title = t.phonePstnPressKeyInstruction;
      subtitle = t.phonePstnPressKeyCountdown(remaining);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
      error: (_, _) => const SizedBox.shrink(),
      data: (status) {
        final isGood = status.isInProgress;
        final color = isGood ? AppColors.success : AppColors.mediumPurple;
        return Container(
          margin: const EdgeInsets.only(top: 6),
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
