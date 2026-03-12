import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';

/// Flag button placed in an AppBar's [actions] list.
/// Shows 🇫🇷 when French is active, 🇬🇧 when English is active.
/// Tapping opens a small dialog to pick the language.
class LanguageSwitcherButton extends ConsumerWidget {
  const LanguageSwitcherButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final flag = lang == 'fr' ? '🇫🇷' : '🇬🇧';

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showPicker(context, ref, lang),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.borderSubtle.withValues(alpha: 0.3),
            ),
          ),
          child: Text(flag, style: const TextStyle(fontSize: 20)),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context, WidgetRef ref, String current) {
    final t = ref.read(translationsProvider);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t.selectLanguage,
          style: GoogleFonts.jost(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LangOption(
              flag: '🇫🇷',
              label: 'Français',
              isSelected: current == 'fr',
              onTap: () {
                ref.read(languageProvider.notifier).state = 'fr';
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
            _LangOption(
              flag: '🇬🇧',
              label: 'English',
              isSelected: current == 'en',
              onTap: () {
                ref.read(languageProvider.notifier).state = 'en';
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String flag;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangOption({
    required this.flag,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppColors.rosePink.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? AppColors.rosePink.withValues(alpha: 0.5)
                : AppColors.borderSubtle.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.rosePink,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
