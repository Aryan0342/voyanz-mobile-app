import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/config/mock_backend.dart';
import 'package:voyanz/core/l10n/app_translations.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
import 'package:voyanz/features/wallet/models/topup_pack.dart';
import 'package:voyanz/features/wallet/providers/wallet_provider.dart';

class TopUpScreen extends ConsumerWidget {
  const TopUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final packsAsync = ref.watch(topUpPacksProvider);
    final selectedPack = ref.watch(selectedPackProvider);
    final userAsync = ref.watch(authStateProvider);
    final credit = userAsync.valueOrNull?.credit;

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.mediumPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: AppColors.mediumPurple, size: 20),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          t.topUp,
          style: GoogleFonts.jost(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.mediumPurple,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.mediumPurple.withValues(alpha: 0.15),
                            AppColors.mediumPurple.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CURRENT BALANCE',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                credit != null
                                    ? credit.toStringAsFixed(2).replaceAll('.', ',')
                                    : '0,00',
                                style: GoogleFonts.jost(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '€',
                                style: GoogleFonts.jost(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      t.selectPack,
                      style: GoogleFonts.jost(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose the best value for your future consultations.',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    packsAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                            color: AppColors.mediumPurple,
                          ),
                        ),
                      ),
                      error: (e, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'An error occurred while loading. Please try again.',
                            style: GoogleFonts.montserrat(color: AppColors.error),
                          ),
                        ),
                      ),
                      data: (packs) => Column(
                        children: packs
                            .map(
                              (pack) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _PackCard(
                                  pack: pack,
                                  t: t,
                                  isSelected: selectedPack?.id == pack.id,
                                  onTap: () =>
                                      ref.read(selectedPackProvider.notifier).state =
                                          pack,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (selectedPack != null)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.mediumPurple.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PromoCodeSection(t: t),
                    const SizedBox(height: 24),
                    _OrderSummary(pack: selectedPack, t: t),
                    const SizedBox(height: 24),
                    GradientButton(
                      width: double.infinity,
                      onPressed: () => _handlePayment(context, ref, selectedPack),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.credit_card, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            t.payWithCard,
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePayment(
    BuildContext context,
    WidgetRef ref,
    TopUpPack pack,
  ) async {
    final t = ref.read(translationsProvider);
    final repo = ref.read(walletRepositoryProvider);
    final promoCode = ref.read(promoCodeProvider);

    try {
      final intent = await repo.createPaymentIntent(
        item: pack.id,
        code: promoCode,
      );

      if (kUseMockBackend) {
        await repo.confirmPayment(intent.clientSecret);
        if (context.mounted) {
          context.push('/wallet/success', extra: {
            'amount': pack.tocomptabilizef,
            'packName': pack.name,
          });
        }
        return;
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: intent.clientSecret,
          merchantDisplayName: 'Voyanz',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      final piParts = intent.clientSecret.split('_secret_');
      final piId = piParts.isNotEmpty ? piParts[0] : '';

      if (piId.isNotEmpty) {
        final status = await repo.confirmPayment(piId);
        if (status.isSuccess && context.mounted) {
          context.push('/wallet/success', extra: {
            'amount': pack.tocomptabilizef,
            'packName': pack.name,
          });
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.paymentFailed),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t.paymentFailed}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _PackCard extends StatelessWidget {
  final TopUpPack pack;
  final AppTranslations t;
  final bool isSelected;
  final VoidCallback onTap;

  const _PackCard({
    required this.pack,
    required this.t,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPremium = pack.promotion > 0 || pack.isFirstPurchaseBonus || pack.name.toLowerCase().contains('premium');

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? AppColors.mediumPurple : const Color(0xFFF3EEFC),
                width: isSelected ? 2 : 1.5,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: AppColors.mediumPurple.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pack.name,
                        style: GoogleFonts.jost(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.mediumPurple : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pay',
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pack.topayf,
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 40),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Receive',
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pack.tocomptabilizef,
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.mediumPurple : AppColors.borderStrong,
                      width: isSelected ? 6 : 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isPremium)
            Positioned(
              top: -12,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.magentaRose,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'BEST VALUE',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PromoCodeSection extends ConsumerStatefulWidget {
  final AppTranslations t;

  const _PromoCodeSection({required this.t});

  @override
  ConsumerState<_PromoCodeSection> createState() => _PromoCodeSectionState();
}

class _PromoCodeSectionState extends ConsumerState<_PromoCodeSection> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F3FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: widget.t.promoCode,
                hintStyle: GoogleFonts.montserrat(
                  color: AppColors.mediumPurple.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              style: GoogleFonts.montserrat(
                color: AppColors.mediumPurple,
                fontWeight: FontWeight.w600,
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _loading
              ? null
              : () async {
                  setState(() => _loading = true);
                  try {
                    final repo = ref.read(walletRepositoryProvider);
                    await repo.validatePromoCode(_controller.text.trim());
                    ref.read(promoCodeProvider.notifier).state =
                        _controller.text.trim();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            widget.t.promoApplied(_controller.text.trim(), ''),
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${widget.t.promoInvalid}: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEBE4FF),
            foregroundColor: AppColors.mediumPurple,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
            minimumSize: const Size(0, 48),
          ),
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.mediumPurple,
                  ),
                )
              : Text(
                  widget.t.applyPromo,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final TopUpPack pack;
  final AppTranslations t;

  const _OrderSummary({required this.pack, required this.t});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'You pay:',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              pack.topayf,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'You receive:',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              pack.tocomptabilizef,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.mediumPurple,
              ),
            ),
          ],
        ),
        if (pack.promotion > 0) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Promo discount:',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '-${pack.promotionf}',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.magentaRose,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
