import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/l10n/app_translations.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _firstNameFocusNode = FocusNode();
  final _lastNameFocusNode = FocusNode();
  final _displayNameFocusNode = FocusNode();
  final _mobileFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  String _role = 'customer';
  String _gender = 'other';
  String _legalStructure = 'individual';
  bool _acceptCgu = false;
  bool _acceptCgs = false;
  bool _acceptCharter = false;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _displayNameFocusNode.dispose();
    _mobileFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _displayNameCtrl.dispose();
    _dobCtrl.dispose();
    _countryCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initialDate = DateTime(now.year - 25, now.month, now.day);
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year - 13, now.month, now.day),
    );
    if (date == null) return;

    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    _dobCtrl.text = '${date.year}-$month-$day';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final t = ref.read(translationsProvider);

    if (!_acceptCgu || !_acceptCgs) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.pleaseAcceptCguCgs)),
      );
      return;
    }

    if (_role == 'professional' && !_acceptCharter) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.pleaseAcceptCharter)),
      );
      return;
    }

    await ref.read(authStateProvider.notifier).signUp(
          body: _buildSignUpBody(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  Map<String, dynamic> _buildSignUpBody() {
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final body = <String, dynamic>{
      'co_email1': _emailCtrl.text.trim(),
      'co_password': _passwordCtrl.text,
      'co_firstname': firstName,
      'co_name': lastName,
      'co_fullname': '$firstName $lastName'.trim(),
      'co_type': _role,
      'cgv': 'phone',
      'cgs': 'phone',
    };

    void putIfNotEmpty(String key, String value) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) body[key] = trimmed;
    }

    putIfNotEmpty('co_mobile1', _mobileCtrl.text);
    putIfNotEmpty('co_birthday', _dobCtrl.text);
    putIfNotEmpty('co_display_name', _displayNameCtrl.text);
    body['co_gender'] = _gender;

    final countryCode = _countryCodeFor(_countryCtrl.text);
    if (countryCode != null) body['co_country'] = countryCode;

    if (_role == 'professional') {
      body['charter_accepted'] = '1';
      body['co_legal_structure_type'] = _legalStructure;
    }

    return body;
  }

  String? _countryCodeFor(String value) {
    switch (value.trim().toLowerCase()) {
      case 'france':
        return 'FR';
      case 'belgique':
      case 'belgium':
        return 'BE';
      case 'canada':
        return 'CA';
      case 'suisse':
      case 'switzerland':
        return 'CH';
      case 'royaume-uni':
      case 'united kingdom':
        return 'GB';
      case 'etats-unis':
      case 'united states':
        return 'US';
      default:
        return null;
    }
  }

  String _friendlySignUpError(Object? error, AppTranslations t) {
    final message = error
        .toString()
        .replaceFirst(RegExp(r'^Exception:\s*', caseSensitive: false), '')
        .trim();
    final normalized = message.toLowerCase();

    if (normalized.contains('user_exists_already_email')) {
      return t.emailAlreadyRegistered;
    }
    if (normalized.contains('user_exists_already_phone')) {
      return t.phoneAlreadyRegistered;
    }
    if (normalized.contains('email_format_invalid')) {
      return t.invalidEmail;
    }
    if (normalized.contains('phone_not_correct')) {
      return t.invalidPhone;
    }
    if (normalized.contains('password_format_invalid')) {
      return t.passwordRules;
    }
    if (normalized.contains('recaptcha_token_error')) {
      return t.signupRecaptchaRequired;
    }
    if (normalized.contains('cgu_mandatory') ||
        normalized.contains('cgs_mandatory')) {
      return t.pleaseAcceptCguCgs;
    }
    if (normalized.contains('charter_mandatory')) {
      return t.pleaseAcceptCharter;
    }
    if (normalized.contains('invalid_legal_structure_type')) {
      return t.invalidLegalStructure;
    }

    return message;
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final authState = ref.watch(authStateProvider);

    ref.listen<AsyncValue<dynamic>>(authStateProvider, (_, next) {
      if (next.hasValue && next.value != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.accountCreated)),
        );
        context.go('/home');
      }
      if (next.hasError) {
        final rawError = next.error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t.createAccountFailed(_friendlySignUpError(rawError, t)),
            ),
          ),
        );
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: VoyanzAppBar(
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.accent,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Image.asset(
                                    'assets/images/voyanz-logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.createAccount,
                                        style: GoogleFonts.jost(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        t.joinCommunity,
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
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: const [
                                _FeaturePill(label: 'Quick setup'),
                                _FeaturePill(label: 'Secure onboarding'),
                                _FeaturePill(label: 'Role-based access'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      GlassCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SegmentedButton<String>(
                                segments: [
                                  ButtonSegment(
                                    value: 'customer',
                                    label: Text(t.customer),
                                    icon: Icon(Icons.person_outline, size: 18),
                                  ),
                                  ButtonSegment(
                                    value: 'professional',
                                    label: Text(t.professional),
                                    icon: Icon(Icons.auto_awesome, size: 18),
                                  ),
                                ],
                                selected: {_role},
                                onSelectionChanged: (v) => setState(() {
                                  _role = v.first;
                                  if (_role != 'professional') {
                                    _acceptCharter = false;
                                  }
                                }),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                t.iIdentifyAs,
                                style: GoogleFonts.manrope(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              SegmentedButton<String>(
                                segments: [
                                  ButtonSegment(
                                    value: 'male',
                                    label: Text(t.male),
                                  ),
                                  ButtonSegment(
                                    value: 'female',
                                    label: Text(t.female),
                                  ),
                                  ButtonSegment(
                                    value: 'other',
                                    label: Text(t.other),
                                  ),
                                ],
                                selected: {_gender},
                                onSelectionChanged: (v) =>
                                    setState(() => _gender = v.first),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      focusNode: _firstNameFocusNode,
                                      controller: _firstNameCtrl,
                                      decoration: InputDecoration(
                                        labelText: t.firstName,
                                      ),
                                      textInputAction: TextInputAction.next,
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      validator: (v) => (v == null || v.isEmpty)
                                          ? t.required
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      focusNode: _lastNameFocusNode,
                                      controller: _lastNameCtrl,
                                      decoration: InputDecoration(
                                        labelText: t.lastName,
                                      ),
                                      textInputAction: TextInputAction.next,
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      validator: (v) => (v == null || v.isEmpty)
                                          ? t.required
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                focusNode: _displayNameFocusNode,
                                controller: _displayNameCtrl,
                                decoration: InputDecoration(
                                  labelText: t.displayName,
                                  prefixIcon: const Icon(Icons.badge_outlined),
                                ),
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                enableSuggestions: false,
                                textCapitalization: TextCapitalization.words,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? t.required
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _dobCtrl,
                                readOnly: true,
                                onTap: _pickBirthDate,
                                decoration: InputDecoration(
                                  labelText: t.dateOfBirth,
                                  hintText: 'YYYY-MM-DD',
                                  prefixIcon: const Icon(Icons.cake_outlined),
                                  suffixIcon: const Icon(
                                    Icons.calendar_month_outlined,
                                  ),
                                ),
                                textInputAction: TextInputAction.next,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? t.required
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                initialValue: null,
                                decoration: InputDecoration(
                                  labelText: t.country,
                                  prefixIcon: const Icon(Icons.flag_outlined),
                                ),
                                items: t.countryList
                                    .map(
                                      (c) => DropdownMenuItem<String>(
                                        value: c,
                                        child: Text(c),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  _countryCtrl.text = value ?? '';
                                },
                                validator: (_) => _countryCtrl.text.isEmpty
                                    ? t.required
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                focusNode: _mobileFocusNode,
                                controller: _mobileCtrl,
                                decoration: InputDecoration(
                                  labelText: t.mobile,
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                ),
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                enableSuggestions: false,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? t.required
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                focusNode: _emailFocusNode,
                                controller: _emailCtrl,
                                decoration: InputDecoration(
                                  labelText: t.email,
                                  prefixIcon: const Icon(Icons.email_outlined),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                enableSuggestions: false,
                                textCapitalization: TextCapitalization.none,
                                validator: (v) {
                                  final value = v?.trim() ?? '';
                                  if (value.isEmpty) return t.emailRequired;
                                  final validEmail = RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  ).hasMatch(value);
                                  return validEmail ? null : t.invalidEmail;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                focusNode: _passwordFocusNode,
                                controller: _passwordCtrl,
                                decoration: InputDecoration(
                                  labelText: t.password,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                ),
                                obscureText: true,
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                enableSuggestions: false,
                                validator: (v) => (v != null && v.length >= 6)
                                    ? null
                                    : t.min6Chars,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                focusNode: _confirmPasswordFocusNode,
                                controller: _confirmPasswordCtrl,
                                decoration: InputDecoration(
                                  labelText: t.confirmPassword,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                ),
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                autocorrect: false,
                                enableSuggestions: false,
                                validator: (v) => v == _passwordCtrl.text
                                    ? null
                                    : t.passwordsNoMatch,
                              ),
                              const SizedBox(height: 14),
                              CheckboxListTile(
                                value: _acceptCgu,
                                onChanged: (v) =>
                                    setState(() => _acceptCgu = v ?? false),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  t.acceptCgu,
                                  style: GoogleFonts.manrope(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              CheckboxListTile(
                                value: _acceptCgs,
                                onChanged: (v) =>
                                    setState(() => _acceptCgs = v ?? false),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  t.acceptCgs,
                                  style: GoogleFonts.manrope(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 240),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                child: _role == 'professional'
                                    ? Column(
                                        key: const ValueKey(
                                          'professional-signup-fields',
                                        ),
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          const SizedBox(height: 12),
                                          DropdownButtonFormField<String>(
                                            initialValue: _legalStructure,
                                            decoration: InputDecoration(
                                              labelText: t.legalStructure,
                                              prefixIcon: const Icon(
                                                Icons.business_center_outlined,
                                              ),
                                            ),
                                            items: [
                                              DropdownMenuItem(
                                                value: 'individual',
                                                child: Text(t.legalIndividual),
                                              ),
                                              DropdownMenuItem(
                                                value: 'company',
                                                child: Text(t.legalCompany),
                                              ),
                                              DropdownMenuItem(
                                                value: 'association',
                                                child: Text(t.legalAssociation),
                                              ),
                                            ],
                                            onChanged: (value) => setState(
                                              () => _legalStructure =
                                                  value ?? 'individual',
                                            ),
                                          ),
                                          CheckboxListTile(
                                            value: _acceptCharter,
                                            onChanged: (v) => setState(
                                              () => _acceptCharter = v ?? false,
                                            ),
                                            controlAffinity:
                                                ListTileControlAffinity.leading,
                                            contentPadding: EdgeInsets.zero,
                                            title: Text(
                                              t.acceptCharter,
                                              style: GoogleFonts.manrope(
                                                color: AppColors.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              const SizedBox(height: 28),
                              GradientButton(
                                onPressed: authState.isLoading ? null : _submit,
                                width: double.infinity,
                                child: authState.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(t.createAccount),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => context.pop(),
                                child: Text.rich(
                                  TextSpan(
                                    text: t.alreadyHaveAccount,
                                    style: GoogleFonts.manrope(
                                      color: AppColors.textMuted,
                                      fontSize: 14,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: t.logIn,
                                        style: GoogleFonts.manrope(
                                          color: AppColors.rosePink,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final String label;

  const _FeaturePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
