import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/features/professionals/providers/professional_account_provider.dart';
import 'package:voyanz/features/professionals/providers/cgs_provider.dart';

/// Shown in place of the professional space while the updated professional
/// CGS have not been accepted (contract P3), the same way voyanz.com blocks
/// its own pro area.
class ProfessionalCgsGate extends ConsumerStatefulWidget {
  const ProfessionalCgsGate({super.key});

  @override
  ConsumerState<ProfessionalCgsGate> createState() =>
      _ProfessionalCgsGateState();
}

class _ProfessionalCgsGateState extends ConsumerState<ProfessionalCgsGate> {
  bool _accepted = false;
  bool _submitting = false;

  Future<void> _submit() async {
    final t = ref.read(translationsProvider);
    setState(() => _submitting = true);
    try {
      await ref.read(professionalAccountRepositoryProvider).acceptCgs();
      // Clear the refusal that opened this gate, then reload the profile.
      ref.read(cgsRequiredProvider.notifier).state = false;
      ref.invalidate(professionalProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.cgsAccepted),
          backgroundColor: AppColors.online,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim(),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final language = ref.watch(languageProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        children: [
          const Icon(
            Icons.gavel_rounded,
            size: 44,
            color: AppColors.rosePink,
          ),
          const SizedBox(height: 18),
          Text(
            t.cgsUpdatedTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t.cgsUpdatedBody,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: () => launchUrl(
              Uri.parse('https://voyanz.com/$language/cgs'),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(t.readCgs),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.rosePink,
              side: const BorderSide(color: AppColors.rosePink),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 18),
          CheckboxListTile(
            value: _accepted,
            onChanged: (value) => setState(() => _accepted = value ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.brandPink,
            title: Text(
              t.cgsAcceptCheckbox,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: (!_accepted || _submitting) ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandPink,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(t.cgsValidate),
          ),
        ],
      ),
    );
  }
}
