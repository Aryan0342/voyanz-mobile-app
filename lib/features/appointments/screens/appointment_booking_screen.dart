import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/config/mock_backend.dart';
import 'package:voyanz/core/l10n/app_translations.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/features/appointments/providers/appointments_provider.dart';
import 'package:voyanz/features/professionals/models/professional.dart';
import 'package:voyanz/features/professionals/providers/professionals_provider.dart';
import 'package:voyanz/features/wallet/providers/wallet_provider.dart';

class AppointmentBookingScreen extends ConsumerStatefulWidget {
  final String coId;

  const AppointmentBookingScreen({super.key, required this.coId});

  @override
  ConsumerState<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState
    extends ConsumerState<AppointmentBookingScreen> {
  String? _selectedSlotKey;
  Map<String, dynamic>? _selectedSlot;
  bool _isProcessing = false;

  String? _rateDisplay(ProfessionalDetail detail) {
    final rates = <double?>[
      detail.pricePhonePerMinute,
      detail.priceVideoPerMinute,
      detail.priceChatPerMinute,
      detail.pricePerMinute,
    ];
    for (final r in rates) {
      if (r != null && r > 0) {
        final normalized = r > 20 ? r / 100 : r;
        return '€${normalized.toStringAsFixed(2)}';
      }
    }
    return null;
  }

  Future<void> _registerAndPay(
    String apId,
    String professionalName,
    String rateStr,
  ) async {
    final t = ref.read(translationsProvider);
    setState(() => _isProcessing = true);

    try {
      await ref.read(appointmentsRepositoryProvider).register(apId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.registrationFailed),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final repo = ref.read(walletRepositoryProvider);

      final intent = await repo.createPaymentIntent(
        item: 'registration_$apId',
      );

      if (kUseMockBackend) {
        await repo.confirmPayment(intent.clientSecret);
        if (!mounted) return;
        context.pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.appointmentPaidSuccess),
            backgroundColor: AppColors.success,
          ),
        );
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
        if (!mounted) return;

        if (status.isSuccess) {
          context.pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.appointmentPaidSuccess),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.appointmentPayFailed),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${t.appointmentPayFailed}: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final proAsync = ref.watch(professionalDetailProvider(widget.coId));
    final dispoAsync = ref.watch(professionalDisponibilitiesProvider);

    return GradientScaffold(
      appBar: VoyanzAppBar(
        showBackButton: true,
        title: Text(
          t.bookAppointment,
          style: GoogleFonts.jost(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: proAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.mediumPurple),
          ),
          error: (e, _) => Center(
            child: Text(
              'An error occurred. Please try again.',
              style: GoogleFonts.montserrat(color: AppColors.textSecondary),
            ),
          ),
          data: (pro) {
            final rateStr = _rateDisplay(pro);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.mediumPurple.withValues(
                          alpha: 0.2,
                        ),
                        child: Text(
                          pro.displayName.isNotEmpty
                              ? pro.displayName[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.jost(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pro.displayName,
                              style: GoogleFonts.jost(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (rateStr != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                t.appointmentRateInfo.replaceAll('%s', rateStr),
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    t.availableSlots,
                    style: GoogleFonts.jost(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: dispoAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.mediumPurple,
                      ),
                    ),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'An error occurred. Please try again.',
                          style: GoogleFonts.montserrat(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    data: (slots) {
                      if (slots.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 64,
                                color: AppColors.textMuted.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                t.noSlotsAvailable,
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
                        padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                        itemCount: slots.length,
                        itemBuilder: (_, i) {
                          final slot = slots[i] as Map<String, dynamic>;
                          final apId = slot['ap_id']?.toString() ??
                              slot['di_id']?.toString() ??
                              '';
                          final day = slot['day']?.toString() ?? '';
                          final rawSlots = slot['slots'];
                          final timeSlots = rawSlots is List
                              ? rawSlots.map((s) => s.toString()).toList()
                              : <String>[];

                          if (apId.isEmpty || timeSlots.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    day,
                                    style: GoogleFonts.jost(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: timeSlots.map((time) {
                                      final key = '$apId|$time';
                                      final selected =
                                          _selectedSlotKey == key;
                                      return GestureDetector(
                                        onTap: () => setState(() {
                                          _selectedSlotKey = key;
                                          _selectedSlot = slot;
                                        }),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? AppColors.mediumPurple
                                                    .withValues(alpha: 0.15)
                                                : AppColors.surfaceLight,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: selected
                                                  ? AppColors.mediumPurple
                                                  : AppColors.borderSubtle,
                                              width: selected ? 1.6 : 1,
                                            ),
                                          ),
                                          child: Text(
                                            time,
                                            style: GoogleFonts.montserrat(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: selected
                                                  ? AppColors.mediumPurple
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                if (_selectedSlot != null) ...[
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      border: Border(
                        top: BorderSide(
                          color: AppColors.borderSubtle,
                          width: 1,
                        ),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: GradientButton(
                        width: double.infinity,
                        onPressed: _isProcessing
                            ? null
                            : () async {
                                final apId = _selectedSlot!['ap_id']
                                        ?.toString() ??
                                    _selectedSlot!['di_id']?.toString() ??
                                    '';
                                if (apId.isEmpty) return;
                                await _registerAndPay(
                                  apId,
                                  pro.displayName,
                                  rateStr ?? '',
                                );
                              },
                        child: _isProcessing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock_outline,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    t.registerAndPay,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
