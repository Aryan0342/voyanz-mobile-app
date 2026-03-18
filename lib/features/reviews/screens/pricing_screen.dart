import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/features/appointments/providers/appointments_provider.dart';
import 'package:voyanz/features/professionals/models/professional.dart';
import 'package:voyanz/features/professionals/providers/professionals_provider.dart';
import 'package:voyanz/features/reviews/providers/reviews_provider.dart';

class PricingScreen extends ConsumerStatefulWidget {
  final String? coId;

  const PricingScreen({super.key, this.coId});

  @override
  ConsumerState<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends ConsumerState<PricingScreen> {
  String? _selectedPricingKey;
  final _promoCtrl = TextEditingController();

  @override
  void dispose() {
    _promoCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyPromoCode() async {
    final t = ref.read(translationsProvider);
    final code = _promoCtrl.text.trim();
    if (code.isEmpty) return;

    try {
      final result = await ref
          .read(reviewsHistoryRepositoryProvider)
          .checkPromoCode(code);
      final valid = result['valid'] == true || result['isValid'] == true;
      final discount =
          result['discount']?.toString() ??
          result['percent']?.toString() ??
          '0';

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            valid ? t.promoApplied(code, discount) : t.promoInvalid,
          ),
          backgroundColor: valid ? AppColors.online : AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.promoCheckFailed(e.toString())),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _registerAppointment() async {
    final t = ref.read(translationsProvider);
    final apIdCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Text(
          t.registerAppointment,
          style: GoogleFonts.jost(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: apIdCtrl,
            decoration: InputDecoration(labelText: t.appointmentId),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? t.required : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: Text(t.registerAppointment),
          ),
        ],
      ),
    );

    if (shouldSubmit != true) return;

    try {
      await ref
          .read(appointmentsRepositoryProvider)
          .register(apIdCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.appointmentRegistered),
          backgroundColor: AppColors.online,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.appointmentRegistrationFailed(e.toString())),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _selectPricing(String key) {
    setState(() {
      _selectedPricingKey = key;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    // If coId is provided, show professional pricing; otherwise show customer pricing
    if (widget.coId != null) {
      final professionalAsync = ref.watch(
        professionalDetailProvider(widget.coId!),
      );
      final listAsync = ref.watch(professionalsListProvider);

      return Scaffold(
        appBar: AppBar(
          title: Text(
            t.sessionPricing,
            style: GoogleFonts.jost(fontSize: 22, fontWeight: FontWeight.w600),
          ),
        ),
        body: professionalAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.rosePink),
          ),
          error: (e, _) => Center(
            child: Text(
              t.errorMessage('$e'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          data: (professional) {
            final list = listAsync.asData?.value ?? const <Professional>[];
            Professional? fromList;
            for (final item in list) {
              if (item.coId == widget.coId) {
                fromList = item;
                break;
              }
            }

            return Column(
              children: [
                Expanded(
                  child: _buildSessionPricingList(
                    professional,
                    fromList: fromList,
                    t: t,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _registerAppointment,
                      icon: const Icon(Icons.event_available),
                      label: Text(t.registerAppointment),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    } else {
      // Original customer pricing screen
      final pricingAsync = ref.watch(customerPricingProvider);

      return Scaffold(
        appBar: AppBar(
          title: Text(
            t.pricing,
            style: GoogleFonts.jost(fontSize: 22, fontWeight: FontWeight.w600),
          ),
        ),
        body: pricingAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.rosePink),
          ),
          error: (e, _) => Center(
            child: Text(
              t.errorMessage('$e'),
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
                      t.noPricingInfo,
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
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promoCtrl,
                          decoration: InputDecoration(
                            labelText: t.promoCode,
                            prefixIcon: const Icon(Icons.local_offer_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: _applyPromoCode,
                        child: Text(t.applyPromo),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: entries.length,
                    itemBuilder: (_, i) {
                      final entry = entries[i];
                      return _buildPricingTile(
                        title: entry.key,
                        value: entry.value.toString(),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
  }

  Widget _buildSessionPricingList(
    dynamic professional, {
    Professional? fromList,
    required dynamic t,
  }) {
    final pricing = <String, String>{};
    final fallback =
        professional.pricePerMinute as double? ?? fromList?.pricePerMinute;
    String formatPrice(double value) {
      final normalized = value > 20 ? value / 100 : value;
      return '€${normalized.toStringAsFixed(2)}/min';
    }

    final phonePrice =
        professional.pricePhonePerMinute as double? ??
        fromList?.pricePhonePerMinute;
    final videoPrice =
        professional.priceVideoPerMinute as double? ??
        fromList?.priceVideoPerMinute;
    final chatPrice =
        professional.priceChatPerMinute as double? ??
        fromList?.priceChatPerMinute;

    final supportsPhone =
        (professional.supportsPhone as bool? ?? false) ||
        (fromList?.supportsPhone ?? false);
    final supportsVideo =
        (professional.supportsVideo as bool? ?? false) ||
        (fromList?.supportsVideo ?? false);
    final supportsChat =
        (professional.supportsChat as bool? ?? false) ||
        (fromList?.supportsChat ?? false);

    if (phonePrice != null) {
      pricing[t.phoneCall] = formatPrice(phonePrice);
    } else if (supportsPhone && fallback != null) {
      pricing[t.phoneCall] = formatPrice(fallback);
    }

    if (videoPrice != null) {
      pricing[t.videoCall] = formatPrice(videoPrice);
    } else if (supportsVideo && fallback != null) {
      pricing[t.videoCall] = formatPrice(fallback);
    }

    if (chatPrice != null) {
      pricing[t.textChat] = formatPrice(chatPrice);
    } else if (supportsChat && fallback != null) {
      pricing[t.textChat] = formatPrice(fallback);
    }

    // Some profiles only provide one generic price without session flags.
    if (pricing.isEmpty && fallback != null) {
      pricing[t.consultation] = formatPrice(fallback);
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
              t.noPricingAvailable,
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
        return _buildPricingTile(title: entry.key, value: entry.value);
      },
    );
  }

  Widget _buildPricingTile({required String title, required String value}) {
    final isSelected = _selectedPricingKey == title;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _selectPricing(title),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isSelected
                  ? AppColors.mediumPurple.withValues(alpha: 0.25)
                  : AppColors.surfaceCard.withValues(alpha: 0.7),
              border: Border.all(
                color: isSelected
                    ? AppColors.rosePink
                    : AppColors.mediumPurple.withValues(alpha: 0.12),
                width: isSelected ? 1.6 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.jost(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.rosePink,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.rosePink,
                      size: 18,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
