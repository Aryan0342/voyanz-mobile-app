import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/features/account/providers/account_provider.dart';

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
  String _role = 'customer';
  String _gender = 'other';
  bool _acceptCgu = false;
  bool _acceptCgs = false;
  bool _loading = false;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  static const _countries = [
    'France',
    'Belgium',
    'Canada',
    'Switzerland',
    'United Kingdom',
    'United States',
    'Other',
  ];

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
    if (!_acceptCgu || !_acceptCgs) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(translationsProvider).pleaseAcceptCguCgs),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(accountRepositoryProvider).createAccount({
        // Preferred backend keys from API spec.
        'co_email1': _emailCtrl.text.trim(),
        'co_mobile1': _mobileCtrl.text.trim(),
        'co_type': _role,
        'cgv': _acceptCgu,
        'cgs': _acceptCgs,

        // Existing app keys kept for compatibility with alternate server mappings.
        'co_first_name': _firstNameCtrl.text.trim(),
        'co_last_name': _lastNameCtrl.text.trim(),
        'co_display_name': _displayNameCtrl.text.trim(),
        'co_gender': _gender,
        'co_birth_date': _dobCtrl.text.trim(),
        'co_country': _countryCtrl.text.trim(),
        'co_mobile': _mobileCtrl.text.trim(),
        'co_email': _emailCtrl.text.trim(),
        'co_password': _passwordCtrl.text,
        'co_password_confirmation': _confirmPasswordCtrl.text,
        'co_accept_cgu': _acceptCgu,
        'co_accept_cgs': _acceptCgs,
        'co_role': _role,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(translationsProvider).accountCreated),
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(translationsProvider).createAccountFailed(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.rosePink.withValues(alpha: 0.15),
                            blurRadius: 32,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/voyanz-logo.png',
                        width: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.createAccount,
                      style: GoogleFonts.jost(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.joinCommunity,
                      style: GoogleFonts.lora(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    GlassCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Role selector ──
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
                              onSelectionChanged: (v) =>
                                  setState(() => _role = v.first),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              t.iIdentifyAs,
                              style: GoogleFonts.montserrat(
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
                                    controller: _firstNameCtrl,
                                    decoration: InputDecoration(
                                      labelText: t.firstName,
                                    ),
                                    textInputAction: TextInputAction.next,
                                    validator: (v) => (v == null || v.isEmpty)
                                        ? t.required
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _lastNameCtrl,
                                    decoration: InputDecoration(
                                      labelText: t.lastName,
                                    ),
                                    textInputAction: TextInputAction.next,
                                    validator: (v) => (v == null || v.isEmpty)
                                        ? t.required
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _displayNameCtrl,
                              decoration: InputDecoration(
                                labelText: t.displayName,
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? t.required : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _dobCtrl,
                              readOnly: true,
                              onTap: _pickBirthDate,
                              decoration: InputDecoration(
                                labelText: t.dateOfBirth,
                                hintText: 'YYYY-MM-DD',
                                prefixIcon: Icon(Icons.cake_outlined),
                                suffixIcon: Icon(Icons.calendar_month_outlined),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? t.required : null,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: null,
                              decoration: InputDecoration(
                                labelText: t.country,
                                prefixIcon: Icon(Icons.flag_outlined),
                              ),
                              items: _countries
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
                                  _countryCtrl.text.isEmpty ? t.required : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _mobileCtrl,
                              decoration: InputDecoration(
                                labelText: t.mobile,
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? t.required : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailCtrl,
                              decoration: InputDecoration(
                                labelText: t.email,
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? t.required : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordCtrl,
                              decoration: InputDecoration(
                                labelText: t.password,
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              obscureText: true,
                              textInputAction: TextInputAction.next,
                              validator: (v) => (v != null && v.length >= 6)
                                  ? null
                                  : t.min6Chars,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordCtrl,
                              decoration: InputDecoration(
                                labelText: t.confirmPassword,
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              validator: (v) => v == _passwordCtrl.text
                                  ? null
                                  : t.passwordsNoMatch,
                            ),
                            const SizedBox(height: 14),
                            CheckboxListTile(
                              value: _acceptCgu,
                              onChanged: (v) =>
                                  setState(() => _acceptCgu = v ?? false),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                t.acceptCgu,
                                style: GoogleFonts.montserrat(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            CheckboxListTile(
                              value: _acceptCgs,
                              onChanged: (v) =>
                                  setState(() => _acceptCgs = v ?? false),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                t.acceptCgs,
                                style: GoogleFonts.montserrat(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            GradientButton(
                              onPressed: _loading ? null : _submit,
                              width: double.infinity,
                              child: _loading
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
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text.rich(
                        TextSpan(
                          text: t.alreadyHaveAccount,
                          style: GoogleFonts.montserrat(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: t.logIn,
                              style: GoogleFonts.montserrat(
                                color: AppColors.rosePink,
                                fontWeight: FontWeight.w600,
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
    );
  }
}
