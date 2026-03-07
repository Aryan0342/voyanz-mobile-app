import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/features/professionals/providers/professionals_provider.dart';

class ProfessionalDetailScreen extends ConsumerWidget {
  final String coId;

  const ProfessionalDetailScreen({super.key, required this.coId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(professionalDetailProvider(coId));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: detailAsync.when(
        loading: () => Container(
          decoration: const BoxDecoration(gradient: AppGradients.background),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.rosePink),
          ),
        ),
        error: (e, _) => Container(
          decoration: const BoxDecoration(gradient: AppGradients.background),
          child: Center(
            child: Text(
              'Error: $e',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
        data: (pro) {
          return Container(
            decoration: const BoxDecoration(gradient: AppGradients.hero),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Column(
                  children: [
                    // ── Avatar ──
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppGradients.accent,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.rosePink.withValues(alpha: 0.35),
                            blurRadius: 32,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: pro.avatar != null
                          ? ClipOval(
                              child: Image.network(
                                pro.avatar!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) =>
                                    _initials(pro),
                              ),
                            )
                          : _initials(pro),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      pro.displayName,
                      style: GoogleFonts.jost(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (pro.specialty != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        pro.specialty!,
                        style: GoogleFonts.lora(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (pro.rating != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...List.generate(5, (i) {
                            return Icon(
                              i < pro.rating!.round()
                                  ? Icons.star
                                  : Icons.star_outline,
                              size: 20,
                              color: AppColors.rosePink,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            pro.rating!.toStringAsFixed(1),
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 28),

                    // ── Info cards ──
                    if (pro.description != null &&
                        pro.description!.isNotEmpty) ...[
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'About',
                              style: GoogleFonts.jost(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              pro.description!,
                              style: GoogleFonts.lora(
                                fontSize: 14,
                                height: 1.6,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    GlassCard(
                      child: Column(
                        children: [
                          if (pro.pricePerMinute != null)
                            _detailRow(
                              Icons.payments_outlined,
                              'Price / min',
                              '${pro.pricePerMinute} €',
                            ),
                          if (pro.phone != null) ...[
                            const Divider(height: 24),
                            _detailRow(
                              Icons.phone_outlined,
                              'Phone',
                              pro.phone!,
                            ),
                          ],
                          if (pro.email != null) ...[
                            const Divider(height: 24),
                            _detailRow(
                              Icons.email_outlined,
                              'Email',
                              pro.email!,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── CTA ──
                    GradientButton(
                      onPressed: () {
                        // TODO: Navigate to session/call creation
                      },
                      width: double.infinity,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.videocam, color: Colors.white),
                          SizedBox(width: 10),
                          Text('Start Session'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _initials(dynamic pro) {
    return Center(
      child: Text(
        pro.displayName.isNotEmpty ? pro.displayName[0].toUpperCase() : '?',
        style: GoogleFonts.jost(
          fontSize: 36,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.rosePink, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: AppColors.textMuted,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
