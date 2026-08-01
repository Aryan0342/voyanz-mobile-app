import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:voyanz/core/l10n/app_translations.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/features/professionals/providers/professional_account_provider.dart';

class ProfessionalAccountScreen extends ConsumerWidget {
  const ProfessionalAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(professionalAccountProvider);
    final t = ref.watch(translationsProvider);

    return GradientScaffold(
      appBar: VoyanzAppBar(
        title: Text(
          t.stripeAccount,
          style: GoogleFonts.jost(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: accountAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    t.failedLoadAccount,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () =>
                        ref.invalidate(professionalAccountProvider),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(t.retry),
                  ),
                ],
              ),
            ),
          ),
          data: (account) => _AccountBody(account: account, t: t),
        ),
      ),
    );
  }
}

class _AccountBody extends StatelessWidget {
  final Map<String, dynamic> account;
  final AppTranslations t;

  const _AccountBody({required this.account, required this.t});

  @override
  Widget build(BuildContext context) {
    final stripeStatus = (
            (account['stripe_status'] ?? account['stripeStatus'])
                    ?.toString() ?? '')
        .toLowerCase();
    final hasStripeAccount =
        (account['hasStripeAccount'] ?? account['has_stripe_account'] ?? false) ==
            true;
    final canReceivePayouts =
        (account['canReceivePayouts'] ?? account['can_receive_payouts'] ?? false) ==
            true;
    final hasRequirements =
        (account['hasRequirements'] ?? account['has_requirements'] ?? false) ==
            true;
    final onboardingUrl =
        (account['stripeOnboardingUrl'] ?? account['onboarding_url'] ?? account['onboardingUrl'])
            ?.toString() ?? '';
    final stripeAccountId =
        (account['stripe_account_id'] ?? account['stripeAccountId'] ?? account['co_id'])
                ?.toString() ?? '';

    final isOnboarded = canReceivePayouts ||
        stripeStatus == 'completed' ||
        stripeStatus == 'enabled' ||
        stripeStatus == 'verified';

    final derivedStatus = isOnboarded
        ? 'completed'
        : hasStripeAccount || hasRequirements || stripeStatus.isNotEmpty
            ? 'pending'
            : stripeStatus;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusCard(
            status: derivedStatus,
            isOnboarded: isOnboarded,
            t: t,
          ),
          const SizedBox(height: 24),
          if (!isOnboarded) ...[
            _ActionCard(
              icon: Icons.payment_outlined,
              title: t.setUpPayments,
              subtitle: t.stripeOnboardingDescription,
              buttonLabel: t.startOnboarding,
              buttonIcon: Icons.open_in_new,
              onTap: () => _handleOnboarding(context, onboardingUrl),
            ),
            const SizedBox(height: 16),
            _InfoBanner(t: t),
          ],
          if (isOnboarded) ...[
            _ActionCard(
              icon: Icons.check_circle_outline,
              title: t.accountActive,
              subtitle: t.stripeAccountActiveMessage,
              buttonLabel: t.viewDashboard,
              buttonIcon: Icons.launch,
              onTap: () => _handleOnboarding(context, onboardingUrl),
            ),
          ],
          if (stripeAccountId.isNotEmpty) ...[
            const SizedBox(height: 24),
            _DetailRow(
              label: t.accountId,
              value: stripeAccountId,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleOnboarding(
      BuildContext context, String url) async {
    if (url.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.noOnboardingUrlAvailable),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.invalidOnboardingUrl),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        throw Exception('Could not launch $url');
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.failedToOpenUrl),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _StatusCard extends StatelessWidget {
  final String status;
  final bool isOnboarded;
  final AppTranslations t;

  const _StatusCard({
    required this.status,
    required this.isOnboarded,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final displayStatus = status.isEmpty ? 'pending' : status;
    final isPending = displayStatus == 'pending' || displayStatus == 'incomplete';

    final statusColor = isOnboarded
        ? AppColors.online
        : isPending
            ? AppColors.warning
            : AppColors.error;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor.withValues(alpha: 0.12),
            ),
            child: Icon(
              isOnboarded
                  ? Icons.check_circle_rounded
                  : isPending
                      ? Icons.schedule_rounded
                      : Icons.error_outline_rounded,
              color: statusColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnboarded
                      ? t.stripeAccountActive
                      : isPending
                          ? t.stripeAccountPending
                          : t.stripeAccountError,
                  style: GoogleFonts.jost(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOnboarded
                      ? t.readyToReceivePayments
                      : isPending
                          ? t.completeOnboardingToReceive
                          : t.stripeAccountErrorDetail,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData buttonIcon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.mediumPurple.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.mediumPurple, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.jost(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          GradientButton(
            onPressed: onTap,
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(buttonIcon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(buttonLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final AppTranslations t;

  const _InfoBanner({required this.t});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.info.withValues(alpha: 0.12),
            ),
            child: const Icon(Icons.info_outline, size: 18, color: AppColors.info),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t.stripeOnboardingInfo,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}



