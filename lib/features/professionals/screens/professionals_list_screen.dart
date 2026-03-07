import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/features/professionals/providers/professionals_provider.dart';

class ProfessionalsListScreen extends ConsumerWidget {
  const ProfessionalsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final professionalsAsync = ref.watch(professionalsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Professionals',
          style: GoogleFonts.jost(fontSize: 22, fontWeight: FontWeight.w600),
        ),
      ),
      body: professionalsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.rosePink),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        data: (pros) {
          if (pros.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No professionals found',
                    style: GoogleFonts.montserrat(
                      color: AppColors.textMuted,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: pros.length,
            itemBuilder: (_, i) {
              final pro = pros[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ProfessionalCard(
                  name: pro.displayName,
                  specialty: pro.specialty,
                  avatarUrl: pro.avatar,
                  isOnline: pro.isOnline == true,
                  rating: pro.rating,
                  pricePerMinute: pro.pricePerMinute,
                  onTap: () => context.push('/professional/${pro.coId}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ProfessionalCard extends StatelessWidget {
  final String name;
  final String? specialty;
  final String? avatarUrl;
  final bool isOnline;
  final double? rating;
  final double? pricePerMinute;
  final VoidCallback onTap;

  const _ProfessionalCard({
    required this.name,
    this.specialty,
    this.avatarUrl,
    required this.isOnline,
    this.rating,
    this.pricePerMinute,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.mediumPurple.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              // ── Avatar with online indicator ──
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.accent,
                    ),
                    child: avatarUrl != null
                        ? ClipOval(
                            child: Image.network(
                              avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) =>
                                  _initials(),
                            ),
                          )
                        : _initials(),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline ? AppColors.online : AppColors.offline,
                        border: Border.all(
                          color: AppColors.surfaceCard,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // ── Info ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (specialty != null && specialty!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        specialty!,
                        style: GoogleFonts.lora(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (rating != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          ...List.generate(5, (i) {
                            return Icon(
                              i < rating!.round()
                                  ? Icons.star
                                  : Icons.star_outline,
                              size: 14,
                              color: AppColors.rosePink,
                            );
                          }),
                          const SizedBox(width: 6),
                          Text(
                            rating!.toStringAsFixed(1),
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // ── Price ──
              if (pricePerMinute != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.rosePink.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${pricePerMinute!.toStringAsFixed(0)}€/min',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.rosePink,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _initials() {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.jost(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
