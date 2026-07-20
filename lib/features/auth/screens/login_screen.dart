import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/config/env.dart';
import 'package:voyanz/core/l10n/app_translations.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscure = true;
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
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authStateProvider.notifier)
        .login(email: _emailCtrl.text.trim(), password: _passwordCtrl.text);
  }

  String _friendlyLoginError(Object? error, AppTranslations t) {
    final message = error.toString();
    final normalized = message.toLowerCase();

    if (normalized.contains('mauvais mot de passe') ||
        normalized.contains('mot de passe incorrect') ||
        normalized.contains('wrong password') ||
        normalized.contains('invalid credentials') ||
        normalized.contains('incorrect email or password') ||
        normalized.contains('bad credentials')) {
      return t.invalidLoginCredentials;
    }

    return message
        .replaceFirst(RegExp(r'^Exception:\s*', caseSensitive: false), '')
        .trim();
  }

  Color _parseHexColor(String? value, Color fallback) {
    if (value == null || value.trim().isEmpty) return fallback;
    final cleaned = value.trim().replaceAll('#', '');
    if (cleaned.length != 6 && cleaned.length != 8) return fallback;
    final hex = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
    final colorValue = int.tryParse(hex, radix: 16);
    if (colorValue == null) return fallback;
    return Color(colorValue);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final t = ref.watch(translationsProvider);
    final agency = ref.watch(agencyProvider);
    final brandPrimary = _parseHexColor(
      agency?.primaryColor,
      AppColors.rosePink,
    );
    final agencyName = agency?.name?.trim();
    final logo = agency?.logo?.trim();

    ref.listen<AsyncValue<dynamic>>(authStateProvider, (_, next) {
      if (next.hasValue && next.value != null) {
        final user = next.value;
        debugPrint(
          'Login success: role=${user?.role} isProfessional=${user?.isProfessional}',
        );
        context.go('/home');
      }
      if (next.hasError) {
        final rawError = next.error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.loginFailed(_friendlyLoginError(rawError, t))),
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
              // HERO SECTION
              Expanded(
                flex: 42,
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
                            // Frosted logo circle
                            Container(
                              width: 74,
                              height: 74,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
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
                              child: (logo != null && logo.isNotEmpty)
                                  ? Image.network(
                                      logo,
                                      fit: BoxFit.contain,
                                      color: Colors.white,
                                      errorBuilder: (_, __, ___) =>
                                          Image.asset(
                                            'assets/images/voyanz-logo.png',
                                            fit: BoxFit.contain,
                                            color: Colors.white,
                                          ),
                                    )
                                  : Image.asset(
                                      'assets/images/voyanz-logo.png',
                                      fit: BoxFit.contain,
                                      color: Colors.white,
                                    ),
                            ),
                            const SizedBox(height: 16),
                            // Brand name
                            Text(
                              (agencyName != null && agencyName.isNotEmpty)
                                  ? agencyName
                                  : 'Voyanz',
                              style: GoogleFonts.jost(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Tagline
                            Text(
                              t.tagline,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
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

              // FORM CARD
              Expanded(
                flex: 58,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(34),
                    ),
                  ),
                  transform: Matrix4.translationValues(0, -30, 0),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 34, 28, 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Heading
                              Text(
                                t.welcomeBack,
                                style: GoogleFonts.jost(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                t.tagline,
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 26),

                              // Email field
                              _LoginTextField(
                                controller: _emailCtrl,
                                focusNode: _emailFocusNode,
                                hintText: t.email,
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                enableSuggestions: false,
                                textCapitalization: TextCapitalization.none,
                                validator: (v) =>
                                    (v == null || v.isEmpty)
                                        ? t.emailRequired
                                        : null,
                              ),
                              const SizedBox(height: 14),

                              // Password field
                              _LoginTextField(
                                controller: _passwordCtrl,
                                focusNode: _passwordFocusNode,
                                hintText: t.password,
                                prefixIcon: Icons.lock_outline,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                autocorrect: false,
                                enableSuggestions: false,
                                suffixIcon: GestureDetector(
                                  onTap: () =>
                                      setState(() => _obscure = !_obscure),
                                  child: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.textMuted,
                                    size: 20,
                                  ),
                                ),
                                validator: (v) =>
                                    (v == null || v.isEmpty)
                                        ? t.passwordRequired
                                        : null,
                                onFieldSubmitted: (_) => _submit(),
                              ),

                              // Forgot password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 8,
                                    ),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    t.forgotPassword,
                                    style: GoogleFonts.manrope(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.mediumPurple,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),

                              // CTA Button - pill shaped
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
                                    : Text(
                                        t.logIn,
                                        style: GoogleFonts.jost(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 28),

                              // Sign-up link
                              Center(
                                child: TextButton(
                                  onPressed: () => context.push('/register'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                  ),
                                  child: Text.rich(
                                    TextSpan(
                                      text: t.noAccount,
                                      style: GoogleFonts.manrope(
                                        color: AppColors.textMuted,
                                        fontSize: 14,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: t.signUp,
                                          style: GoogleFonts.manrope(
                                            color: AppColors.magentaRose,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Clean, lightly-bordered input field matching the reference design.
class _LoginTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool autocorrect;
  final bool enableSuggestions;
  final TextCapitalization textCapitalization;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const _LoginTextField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.focusNode,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.textCapitalization = TextCapitalization.none,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
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
      style: GoogleFonts.manrope(
        fontSize: 15,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.manrope(
          color: AppColors.textMuted,
          fontSize: 15,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(prefixIcon, color: AppColors.textMuted, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 52),
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
          borderSide: const BorderSide(color: Color(0xFFE4E6EF), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE4E6EF), width: 1.2),
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
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
      ),
    );
  }
}