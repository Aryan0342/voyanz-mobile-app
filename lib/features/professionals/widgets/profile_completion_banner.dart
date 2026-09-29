import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/features/professionals/models/professional_profile.dart';
import 'package:voyanz/features/professionals/providers/professional_account_provider.dart';

/// Dashboard banner pointing at whatever still keeps the professional out of
/// the catalogue, the way voyanz.com does on its own dashboard.
///
/// It reads the server's `completion` block rather than judging the profile
/// locally: the server applies rules the app cannot see, such as the minimum
/// description length (P1a). Nothing is shown once the profile is complete,
/// or while the server sends no checklist at all.
class ProfileCompletionBanner extends ConsumerWidget {
  const ProfileCompletionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final profile = ref.watch(professionalProfileProvider).valueOrNull;

    if (profile == null ||
        !profile.hasServerCompletion ||
        profile.completionIsComplete ||
        profile.completionMissing.isEmpty) {
      return const SizedBox.shrink();
    }

    final score = profile.completionScore;
    final labels = profile.completionMissing
        .map((key) => _label(key, t))
        .where((label) => label.isNotEmpty)
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push('/professional-profile'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.completeYourProfile,
                        style: GoogleFonts.jost(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (score != null)
                      Text(
                        t.completeProfileProgress(score),
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                  ],
                ),
                if (score != null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (score / 100).clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: AppColors.surfaceElevated,
                      color: AppColors.warning,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  t.completeProfileWhy,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (labels.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: labels
                        .map(
                          (label) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              label,
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      t.completeProfileCta,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandPink,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: AppColors.brandPink,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Names a `completion.missing` key. An unknown key is dropped rather than
  /// shown raw, so a key added server-side never surfaces as jargon.
  String _label(String key, dynamic t) {
    switch (key.trim().toLowerCase()) {
      case 'photo':
        return t.checklistPhoto;
      case 'description':
        return t.checklistDescription;
      case 'tools':
        return t.checklistCategories;
      case 'specialities':
        return t.checklistSpecialities;
      case 'rates':
      case 'price':
        return t.checklistPrice;
      case 'languages':
        return t.checklistLanguages;
      default:
        return '';
    }
  }
}

/// Exposed for the banner's tests.
bool shouldShowCompletionBanner(ProfessionalProfile? profile) =>
    profile != null &&
    profile.hasServerCompletion &&
    !profile.completionIsComplete &&
    profile.completionMissing.isNotEmpty;
