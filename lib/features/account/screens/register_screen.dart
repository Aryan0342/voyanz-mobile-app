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
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
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
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Column(
            children: [
              // ── HERO SECTION ────────────────────────────────────────────
              SizedBox(
                height: 250,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF5B21B6),
                        Color(0xFF7C3AED),
                        Color(0xFF8B5CF6),
                        Color(0xFFA855F7),
                      ],
                      stops: [0.0, 0.3, 0.65, 1.0],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Frosted square logo card
                            Container(
                              width: 70,
                              height: 70,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.14),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/voyanz-logo.png',
                                fit: BoxFit.contain,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Voyanz',
                              style: GoogleFonts.jost(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.joinCommunity,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.80),
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── FORM CARD ────────────────────────────────────────────────
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(34),
                    ),
                  ),
                  transform: Matrix4.translationValues(0, -26, 0),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                t.createAccount,
                                style: GoogleFonts.jost(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                t.joinCommunity,
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 22),

                              // Role toggle
                              SegmentedButton<String>(
                                segments: [
                                  ButtonSegment(
                                    value: 'customer',
                                    label: Text(t.customer),
                                    icon: const Icon(
                                        Icons.person_outline,
                                        size: 18),
                                  ),
                                  ButtonSegment(
                                    value: 'professional',
                                    label: Text(t.professional),
                                    icon: const Icon(
                                        Icons.auto_awesome,
                                        size: 18),
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
                              const SizedBox(height: 18),

                              // Gender
                              _SectionLabel(t.iIdentifyAs),
                              const SizedBox(height: 8),
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
                              const SizedBox(height: 18),

                              // First + Last name side by side
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _SectionLabel(t.firstName),
                                        const SizedBox(height: 6),
                                        _RegTextField(
                                          controller: _firstNameCtrl,
                                          focusNode: _firstNameFocusNode,
                                          hintText: t.firstName,
                                          textInputAction:
                                              TextInputAction.next,
                                          textCapitalization:
                                              TextCapitalization.words,
                                          autocorrect: false,
                                          enableSuggestions: false,
                                          validator: (v) =>
                                              (v == null || v.isEmpty)
                                                  ? t.required
                                                  : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _SectionLabel(t.lastName),
                                        const SizedBox(height: 6),
                                        _RegTextField(
                                          controller: _lastNameCtrl,
                                          focusNode: _lastNameFocusNode,
                                          hintText: t.lastName,
                                          textInputAction:
                                              TextInputAction.next,
                                          textCapitalization:
                                              TextCapitalization.words,
                                          autocorrect: false,
                                          enableSuggestions: false,
                                          validator: (v) =>
                                              (v == null || v.isEmpty)
                                                  ? t.required
                                                  : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Display name
                              _SectionLabel(t.displayName),
                              const SizedBox(height: 6),
                              _RegTextField(
                                controller: _displayNameCtrl,
                                focusNode: _displayNameFocusNode,
                                hintText: t.displayName,
                                prefixIcon: Icons.badge_outlined,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                                autocorrect: false,
                                enableSuggestions: false,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? t.required
                                    : null,
                              ),
                              const SizedBox(height: 14),

                              // Date of birth
                              _SectionLabel(t.dateOfBirth),
                              const SizedBox(height: 6),
                              _RegTextField(
                                controller: _dobCtrl,
                                hintText: 'YYYY-MM-DD',
                                prefixIcon: Icons.cake_outlined,
                                readOnly: true,
                                onTap: _pickBirthDate,
                                suffixIcon: const Icon(
                                  Icons.calendar_month_outlined,
                                  color: AppColors.textMuted,
                                  size: 20,
                                ),
                                textInputAction: TextInputAction.next,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? t.required
                                    : null,
                              ),
                              const SizedBox(height: 14),

                              // Country
                              _SectionLabel(t.country),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: null,
                                decoration: _dropdownDecoration(
                                    t.country, Icons.flag_outlined),
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
                                validator: (_) =>
                                    _countryCtrl.text.isEmpty
                                        ? t.required
                                        : null,
                              ),
                              const SizedBox(height: 14),

                              // Mobile
                              _SectionLabel(t.mobile),
                              const SizedBox(height: 6),
                              _RegTextField(
                                controller: _mobileCtrl,
                                focusNode: _mobileFocusNode,
                                hintText: t.mobile,
                                prefixIcon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                enableSuggestions: false,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? t.required
                                    : null,
                              ),
                              const SizedBox(height: 14),

                              // Email
                              _SectionLabel(t.email),
                              const SizedBox(height: 6),
                              _RegTextField(
                                controller: _emailCtrl,
                                focusNode: _emailFocusNode,
                                hintText: t.email,
                                prefixIcon: Icons.email_outlined,
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
                              const SizedBox(height: 14),

                              // Password
                              _SectionLabel(t.password),
                              const SizedBox(height: 6),
                              _RegTextField(
                                controller: _passwordCtrl,
                                focusNode: _passwordFocusNode,
                                hintText: t.password,
                                prefixIcon: Icons.lock_outline,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                enableSuggestions: false,
                                suffixIcon: GestureDetector(
                                  onTap: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                  child: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.textMuted,
                                    size: 20,
                                  ),
                                ),
                                validator: (v) =>
                                    (v != null && v.length >= 6)
                                        ? null
                                        : t.min6Chars,
                              ),
                              const SizedBox(height: 14),

                              // Confirm password
                              _SectionLabel(t.confirmPassword),
                              const SizedBox(height: 6),
                              _RegTextField(
                                controller: _confirmPasswordCtrl,
                                focusNode: _confirmPasswordFocusNode,
                                hintText: t.confirmPassword,
                                prefixIcon: Icons.lock_outline,
                                obscureText: _obscureConfirm,
                                textInputAction: TextInputAction.done,
                                autocorrect: false,
                                enableSuggestions: false,
                                suffixIcon: GestureDetector(
                                  onTap: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm),
                                  child: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.textMuted,
                                    size: 20,
                                  ),
                                ),
                                validator: (v) =>
                                    v == _passwordCtrl.text
                                        ? null
                                        : t.passwordsNoMatch,
                              ),
                              const SizedBox(height: 14),

                              // CGU checkbox
                              GestureDetector(
                                onTap: () => setState(() => _acceptCgu = !_acceptCgu),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Checkbox(
                                      value: _acceptCgu,
                                      onChanged: (v) => setState(() => _acceptCgu = v ?? false),
                                      activeColor: AppColors.mediumPurple,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          t.acceptCgu,
                                          style: GoogleFonts.manrope(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                            height: 1.45,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),

                              // CGS checkbox
                              GestureDetector(
                                onTap: () => setState(() => _acceptCgs = !_acceptCgs),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Checkbox(
                                      value: _acceptCgs,
                                      onChanged: (v) => setState(() => _acceptCgs = v ?? false),
                                      activeColor: AppColors.mediumPurple,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          t.acceptCgs,
                                          style: GoogleFonts.manrope(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                            height: 1.45,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Professional-only fields
                              AnimatedSwitcher(
                                duration:
                                    const Duration(milliseconds: 240),
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
                                          const SizedBox(height: 14),
                                          DropdownButtonFormField<String>(
                                            initialValue: _legalStructure,
                                            decoration: _dropdownDecoration(
                                              t.legalStructure,
                                              Icons
                                                  .business_center_outlined,
                                            ),
                                            items: [
                                              DropdownMenuItem(
                                                value: 'individual',
                                                child: Text(
                                                    t.legalIndividual),
                                              ),
                                              DropdownMenuItem(
                                                value: 'company',
                                                child:
                                                    Text(t.legalCompany),
                                              ),
                                              DropdownMenuItem(
                                                value: 'association',
                                                child: Text(
                                                    t.legalAssociation),
                                              ),
                                            ],
                                            onChanged: (value) =>
                                                setState(
                                              () => _legalStructure =
                                                  value ?? 'individual',
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          GestureDetector(
                                            onTap: () => setState(() =>
                                                _acceptCharter =
                                                    !_acceptCharter),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Checkbox(
                                                  value: _acceptCharter,
                                                  onChanged: (v) =>
                                                      setState(
                                                    () => _acceptCharter =
                                                        v ?? false,
                                                  ),
                                                  activeColor: AppColors
                                                      .mediumPurple,
                                                  materialTapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                  visualDensity:
                                                      VisualDensity
                                                          .compact,
                                                  shape:
                                                      RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(4),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets
                                                            .only(top: 2),
                                                    child: Text(
                                                      t.acceptCharter,
                                                      style: GoogleFonts
                                                          .manrope(
                                                        fontSize: 13,
                                                        color: AppColors
                                                            .textSecondary,
                                                        height: 1.45,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              ),

                              const SizedBox(height: 28),

                              // CTA Button
                              GradientButton(
                                onPressed:
                                    authState.isLoading ? null : _submit,
                                width: double.infinity,
                                height: 56,
                                borderRadius: BorderRadius.circular(32),
                                child: authState.isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            t.createAccount,
                                            style: GoogleFonts.jost(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_forward,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                              ),
                              const SizedBox(height: 28),

                              // Already have account section
                              Center(
                                child: Column(
                                  children: [
                                    Text(
                                      t.alreadyHaveAccount,
                                      style: GoogleFonts.manrope(
                                        color: AppColors.textMuted,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextButton(
                                      onPressed: () => context.pop(),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize
                                            .shrinkWrap,
                                      ),
                                      child: Text(
                                        t.logIn,
                                        style: GoogleFonts.manrope(
                                          color: AppColors.mediumPurple,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
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
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.manrope(color: AppColors.textMuted, fontSize: 15),
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Icon(icon, color: AppColors.textMuted, size: 20),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 52),
      filled: true,
      fillColor: const Color(0xFFF4F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE4E6EF), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE4E6EF), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            const BorderSide(color: AppColors.mediumPurple, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    );
  }
}

/// Small label displayed above each field group.
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

/// Clean, lightly-bordered input field consistent with the login screen design.
class _RegTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool autocorrect;
  final bool enableSuggestions;
  final TextCapitalization textCapitalization;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final bool readOnly;
  final VoidCallback? onTap;

  const _RegTextField({
    required this.controller,
    required this.hintText,
    this.focusNode,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.textCapitalization = TextCapitalization.none,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      textCapitalization: textCapitalization,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      readOnly: readOnly,
      onTap: onTap,
      style: GoogleFonts.manrope(
        fontSize: 15,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle:
            GoogleFonts.manrope(color: AppColors.textMuted, fontSize: 15),
        prefixIcon: prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child:
                    Icon(prefixIcon, color: AppColors.textMuted, size: 20),
              )
            : null,
        prefixIconConstraints: prefixIcon != null
            ? const BoxConstraints(minWidth: 52)
            : null,
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 14),
                child: suffixIcon,
              )
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 48),
        filled: true,
        fillColor: const Color(0xFFF4F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Color(0xFFE4E6EF), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Color(0xFFE4E6EF), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.mediumPurple,
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.error, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
      ),
    );
  }
}
