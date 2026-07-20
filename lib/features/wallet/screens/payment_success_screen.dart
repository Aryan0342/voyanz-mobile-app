import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/widgets.dart';

class PaymentSuccessScreen extends ConsumerWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final amount = extra?['amount'] as String? ?? '';
    final packName = extra?['packName'] as String? ?? '';

    return GradientScaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  t.paymentSuccess,
                  style: GoogleFonts.jost(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (amount.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${t.creditReceived}: $amount',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (packName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    packName,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                GradientButton(
                  width: double.infinity,
                  onPressed: () {
                    while (context.canPop()) {
                      context.pop();
                    }
                    context.pushReplacement('/wallet');
                  },
                  child: Text(t.backToWallet),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
