import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/l10n/app_translations.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
import 'package:voyanz/features/sessions/models/session_status.dart';
import 'package:voyanz/features/sessions/providers/sessions_provider.dart';

class ChatSessionScreen extends ConsumerStatefulWidget {
  final String seId;
  final String coId;

  const ChatSessionScreen({super.key, required this.seId, required this.coId});

  @override
  ConsumerState<ChatSessionScreen> createState() => _ChatSessionScreenState();
}

class _ChatSessionScreenState extends ConsumerState<ChatSessionScreen> {
  bool _sessionEndedHandled = false;

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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                  ],
                ),
                _SessionStatusBanner(
                  statusAsync: liveStatusAsync,
                  t: t,
                  isProfessional: isProfessional,
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
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                    size: 52,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  t.chatSession,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jost(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${t.session} #${widget.seId}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  t.sessionReady,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(color: AppColors.textMuted),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => context.go('/chat'),
                  icon: const Icon(Icons.forum_outlined),
                  label: Text(t.openConversations),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  label: Text(t.endSession),
                ),
              ],
            ),
          ),
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
