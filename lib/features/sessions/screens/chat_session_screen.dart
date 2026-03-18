import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';

class ChatSessionScreen extends ConsumerWidget {
  final String seId;
  final String coId;

  const ChatSessionScreen({super.key, required this.seId, required this.coId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

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
                  '${t.session} #$seId',
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
