import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/features/professionals/providers/professionals_provider.dart';
import 'package:voyanz/features/reviews/providers/reviews_provider.dart';

class PricingScreen extends ConsumerWidget {
  final String? coId;

  const PricingScreen({super.key, this.coId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If coId is provided, show professional pricing; otherwise show customer pricing
    if (coId != null) {
      final professionalAsync = ref.watch(professionalDetailProvider(coId!));

      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Session Pricing',
            style: GoogleFonts.jost(fontSize: 22, fontWeight: FontWeight.w600),
          ),
        ),
        body: professionalAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.rosePink),
          ),
          error: (e, _) => Center(
            child: Text(
              'Error: $e',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          data: (professional) {
            return _buildSessionPricingList(professional);
          },
        ),
      );
    } else {
      // Original customer pricing screen
      final pricingAsync = ref.watch(customerPricingProvider);

      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Pricing',
            style: GoogleFonts.jost(fontSize: 22, fontWeight: FontWeight.w600),
          ),
        ),
        body: pricingAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.rosePink),
          ),
          error: (e, _) => Center(
            child: Text(
              'Error: $e',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          data: (pricing) {
            if (pricing.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      size: 64,
                      color: AppColors.textMuted.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No pricing information',
                      style: GoogleFonts.montserrat(
                        color: AppColors.textMuted,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }
            final entries = pricing.entries.toList();
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: entries.length,
              itemBuilder: (_, i) {
                final entry = entries[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: i == 0 ? AppGradients.accent : null,
                      color: i == 0
                          ? null
                          : AppColors.surfaceCard.withValues(alpha: 0.7),
                      border: i == 0
                          ? null
                          : Border.all(
                              color: AppColors.mediumPurple.withValues(
                                alpha: 0.12,
                              ),
                            ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: GoogleFonts.montserrat(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: i == 0
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            entry.value.toString(),
                            style: GoogleFonts.jost(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: i == 0 ? Colors.white : AppColors.rosePink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
    }
  }

  Widget _buildSessionPricingList(dynamic professional) {
    final pricing = <String, String>{};

    if (professional.supportsPhone &&
        professional.pricePhonePerMinute != null) {
      pricing['Phone Call'] =
          '€${(professional.pricePhonePerMinute! / 100).toStringAsFixed(2)}/min';
    }

    if (professional.supportsVideo &&
        professional.priceVideoPerMinute != null) {
      pricing['Video Call'] =
          '€${(professional.priceVideoPerMinute! / 100).toStringAsFixed(2)}/min';
    }

    if (professional.supportsChat && professional.priceChatPerMinute != null) {
      pricing['Text Chat'] =
          '€${(professional.priceChatPerMinute! / 100).toStringAsFixed(2)}/min';
    }

    if (pricing.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.payments_outlined,
              size: 64,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No pricing information available',
              style: GoogleFonts.montserrat(
                color: AppColors.textMuted,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final entries = pricing.entries.toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final entry = entries[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: i == 0 ? AppGradients.accent : null,
              color: i == 0
                  ? null
                  : AppColors.surfaceCard.withValues(alpha: 0.7),
              border: i == 0
                  ? null
                  : Border.all(
                      color: AppColors.mediumPurple.withValues(alpha: 0.12),
                    ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: i == 0 ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    entry.value,
                    style: GoogleFonts.jost(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: i == 0 ? Colors.white : AppColors.rosePink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
