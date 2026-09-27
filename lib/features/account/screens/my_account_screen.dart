import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/config/countries.dart';
import 'package:voyanz/core/l10n/app_translations.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/core/utils/date_utils.dart';
import 'package:voyanz/features/account/data/account_repository.dart';
import 'package:voyanz/features/account/providers/account_provider.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';

/// The identity, contact and legal details behind `PUT /web/1.0/account/:co_id`
/// — the app's counterpart of the website's "My Account" page.
///
/// The public profile (display name, bio, rates, categories) lives on the
/// professional profile screen instead, exactly as the website splits "My
/// Account" from "My Description". Email and password stay on the account and
/// security screen, so no field is editable in two places.
class MyAccountScreen extends ConsumerStatefulWidget {
  const MyAccountScreen({super.key});

  @override
  ConsumerState<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends ConsumerState<MyAccountScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _mobile = TextEditingController();
  final _birthday = TextEditingController();
  final _society = TextEditingController();
  final _siret = TextEditingController();
  final _iban = TextEditingController();
  final _address1 = TextEditingController();
  final _address2 = TextEditingController();
  final _zip = TextEditingController();
  final _city = TextEditingController();

  String? _country;
  String? _sex;
  String? _legalStructure;

  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  String _initialMobile = '';

  /// What the server actually returned, so the save can send only what the
  /// professional changed. `GET /web/1.0/user/infos` omits most of these
  /// fields (verified 2026-09-28), so sending the whole form would overwrite
  /// real values with the blanks it could not prefill.
  final Map<String, String> _loaded = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _lastName,
      _mobile,
      _birthday,
      _society,
      _siret,
      _iban,
      _address1,
      _address2,
      _zip,
      _city,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Fills the form from `GET /web/1.0/user/infos`, which returns the stored
  /// account record.
  Future<void> _load() async {
    try {
      final data = await ref.read(accountRepositoryProvider).getUserInfos();
      if (!mounted) return;
      String field(String key) => (data[key] ?? '').toString().trim();

      _firstName.text = field('co_firstname');
      _lastName.text = field('co_name');
      _mobile.text = field('co_mobile1');
      _initialMobile = _mobile.text;
      _birthday.text = _dateOnly(field('co_birthday'));
      _society.text = field('co_society');
      _siret.text = field('co_siret');
      _iban.text = field('co_iban');
      _address1.text = field('co_address1');
      _address2.text = field('co_address2');
      _zip.text = field('co_zip');
      _city.text = field('co_city');

      final sex = field('co_sex').toLowerCase();
      final structure = field('co_legal_structure_type').toLowerCase();

      _loaded
        ..['co_firstname'] = _firstName.text
        ..['co_name'] = _lastName.text
        ..['co_mobile1'] = _mobile.text
        ..['co_birthday'] = _birthday.text
        ..['co_society'] = _society.text
        ..['co_siret'] = _siret.text
        ..['co_iban'] = _iban.text
        ..['co_address1'] = _address1.text
        ..['co_address2'] = _address2.text
        ..['co_zip'] = _zip.text
        ..['co_city'] = _city.text
        ..['co_sex'] = sex
        ..['co_country'] = normalizeCountryCode(field('co_country')) ?? ''
        ..['co_legal_structure_type'] = structure;

      setState(() {
        _country = normalizeCountryCode(field('co_country'));
        // Left unset when the server did not say: a default would claim a
        // value the account may not have, and saving it would write it.
        _sex = const {'male', 'female', 'na'}.contains(sex) ? sex : null;
        // "association" exists on legacy accounts and the server keeps it on
        // update, but it cannot be chosen here (signup rejects it).
        _legalStructure = structure.isEmpty
            ? null
            : (structure == 'company' ? 'company' : 'individual');
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = _clean(e);
        _loading = false;
      });
    }
  }

  /// The server sends placeholder dates such as `0000-00-00`; show nothing.
  String _dateOnly(String raw) {
    final value = raw.split(' ').first;
    if (value.isEmpty || value.startsWith('0000') || value.startsWith('1899')) {
      return '';
    }
    return value;
  }

  String _clean(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.online,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: error ? 6 : 4),
      ),
    );
  }

  Future<void> _pickBirthday(AppTranslations t) async {
    final now = DateTime.now();
    final current = DateTime.tryParse(_birthday.text);
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: t.dateOfBirth,
    );
    if (picked == null) return;
    setState(() {
      _birthday.text = picked.toIso8601String().split('T').first;
    });
  }

  Future<void> _save() async {
    final t = ref.read(translationsProvider);
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null || user.coId.isEmpty) return;

    final isProfessional = user.isProfessional == true;
    if (isProfessional &&
        _legalStructure == 'company' &&
        _society.text.trim().length < 3) {
      return _toast(t.societyRequired, error: true);
    }

    // Only what actually changed. The endpoint merges (P4 changes the password,
    // the email or the mobile on their own), and sending a field the server
    // never returned would replace a real value with a blank.
    final current = <String, String>{
      'co_firstname': _firstName.text.trim(),
      'co_name': _lastName.text.trim(),
      'co_mobile1': _mobile.text.trim(),
      'co_birthday': _birthday.text.trim(),
      'co_sex': _sex ?? '',
      'co_country': _country ?? '',
      'co_address1': _address1.text.trim(),
      'co_address2': _address2.text.trim(),
      'co_zip': _zip.text.trim(),
      'co_city': _city.text.trim(),
      if (isProfessional) ...{
        'co_legal_structure_type': _legalStructure ?? '',
        'co_society': _society.text.trim(),
        'co_siret': _siret.text.trim(),
        'co_iban': _iban.text.trim(),
      },
    };

    final body = <String, dynamic>{};
    current.forEach((key, value) {
      if (value != (_loaded[key] ?? '')) body[key] = value;
    });

    if (body.isEmpty) return _toast(t.nothingToSave);

    setState(() => _saving = true);
    try {
      final response = await ref
          .read(accountRepositoryProvider)
          .updateAccount(user.coId, body);

      // P4: a changed mobile has to be verified by SMS again, and until it is
      // the professional is absent from the catalogue.
      final needsReverification =
          mobileReverificationRequired(response) &&
          _mobile.text.trim() != _initialMobile;

      await ref.read(authStateProvider.notifier).fetchUser();
      _initialMobile = _mobile.text.trim();
      _loaded.addAll(current);
      _toast(
        needsReverification ? t.mobileReverificationNeeded : t.accountUpdated,
        error: needsReverification,
      );
    } catch (e) {
      _toast(_clean(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final isProfessional =
        ref.watch(authStateProvider).valueOrNull?.isProfessional == true;

    return GradientScaffold(
      appBar: VoyanzAppBar(
        title: Text(
          t.myAccount,
          style: GoogleFonts.lora(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.mediumPurple),
              )
            : _loadError != null
            ? _ErrorState(message: _loadError!, onRetry: _retry, label: t.retry)
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      t.accountPartialLoadNotice,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        height: 1.4,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  _Section(
                    title: t.identitySection,
                    children: [
                      _field(_firstName, t.firstName),
                      const SizedBox(height: 12),
                      _field(_lastName, t.lastName),
                      const SizedBox(height: 12),
                      _genderPicker(t),
                      const SizedBox(height: 12),
                      _birthdayField(t),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _Section(
                    title: t.contactSection,
                    children: [
                      _field(
                        _mobile,
                        t.mobile,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      _countryPicker(t),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _Section(
                    title: t.addressSection,
                    children: [
                      _field(_address1, t.addressLine1),
                      const SizedBox(height: 12),
                      _field(_address2, t.addressLine2),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              _zip,
                              t.postalCode,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(flex: 2, child: _field(_city, t.cityLabel)),
                        ],
                      ),
                    ],
                  ),
                  if (isProfessional) ...[
                    const SizedBox(height: 18),
                    _Section(
                      title: t.legalSection,
                      children: [
                        _legalStructurePicker(t),
                        if (_legalStructure == 'company') ...[
                          const SizedBox(height: 12),
                          _field(_society, t.companyName),
                        ],
                        const SizedBox(height: 12),
                        _field(
                          _siret,
                          t.siretNumber,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z0-9 \-/]'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _field(_iban, t.iban),
                        const SizedBox(height: 6),
                        Text(
                          t.ibanHint,
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            height: 1.4,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandPink,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(t.saveChanges),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _retry() {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    _load();
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.montserrat(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(color: AppColors.textMuted),
      ),
    );
  }

  Widget _birthdayField(AppTranslations t) {
    return InkWell(
      onTap: () => _pickBirthday(t),
      child: IgnorePointer(
        child: _field(_birthday, t.dateOfBirth),
      ),
    );
  }

  Widget _genderPicker(AppTranslations t) {
    final options = <String, String>{
      'male': t.male,
      'female': t.female,
      'na': t.other,
    };
    return Row(
      children: [
        Text(
          t.gender,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            spacing: 8,
            children: options.entries
                .map(
                  (entry) => ChoiceChip(
                    label: Text(entry.value),
                    selected: _sex == entry.key,
                    onSelected: (_) => setState(() => _sex = entry.key),
                    backgroundColor: AppColors.surfaceElevated,
                    selectedColor: AppColors.brandPink.withValues(alpha: 0.28),
                    labelStyle: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _countryPicker(AppTranslations t) {
    final entries = kCountries.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return DropdownButtonFormField<String>(
      initialValue: _country,
      isExpanded: true,
      dropdownColor: AppColors.surfaceElevated,
      decoration: InputDecoration(
        labelText: t.country,
        labelStyle: GoogleFonts.montserrat(color: AppColors.textMuted),
      ),
      style: GoogleFonts.montserrat(color: AppColors.textPrimary),
      items: entries
          .map(
            (entry) => DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (value) => setState(() => _country = value),
    );
  }

  Widget _legalStructurePicker(AppTranslations t) {
    final options = <String, String>{
      'individual': t.individualStructure,
      'company': t.companyStructure,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: options.entries
          .map(
            (entry) => InkWell(
              onTap: () => setState(() => _legalStructure = entry.key),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      _legalStructure == entry.key
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: _legalStructure == entry.key
                          ? AppColors.brandPink
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.jost(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.label,
  });

  final String message;
  final VoidCallback onRetry;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
