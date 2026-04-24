import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/l10n/app_translations.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
import 'package:voyanz/features/sessions/data/sessions_data_source.dart';
import 'package:voyanz/features/sessions/models/session_status.dart';
import 'package:voyanz/features/sessions/providers/sessions_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsed += const Duration(seconds: 1));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.online.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
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
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.mediumPurple.withValues(alpha: 0.2),
                    ),
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
                    shape: BoxShape.circle,
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
                  t.phoneSession,
                  style: GoogleFonts.jost(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${t.session} #${widget.seId}',
                  style: GoogleFonts.montserrat(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  t.sessionReady,
                  style: GoogleFonts.montserrat(color: AppColors.textMuted),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.call_end),
                    label: Text(t.endSession),
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
        color: AppColors.deepIndigo.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
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
          margin: const EdgeInsets.only(top: 6),
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
