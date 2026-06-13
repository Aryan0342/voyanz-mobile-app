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
    final agencyTag = EnvConfig.current.baseUrl.replaceFirst(
      RegExp(r'^https?://'),
      '',
    );

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
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            GlassCard(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        padding: const EdgeInsets.all(11),
                                        decoration: BoxDecoration(
                                          gradient: AppGradients.accent,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: brandPrimary.withValues(
                                                alpha: 0.24,
                                              ),
                                              blurRadius: 18,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: (logo != null && logo.isNotEmpty)
                                            ? Image.network(
                                                logo,
                                                fit: BoxFit.contain,
                                                errorBuilder: (_, __, ___) =>
                                                    Image.asset(
                                                      'assets/images/voyanz-logo.png',
                                                      fit: BoxFit.contain,
                                                    ),
                                              )
                                            : Image.asset(
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
                                              (agencyName != null &&
                                                      agencyName.isNotEmpty)
                                                  ? agencyName
                                                  : 'Voyanz',
                                              style: GoogleFonts.jost(
                                                fontSize: 28,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.mediumPurple,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              agencyTag,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.manrope(
                                                fontSize: 12,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 22),
                                  Text(
                                    t.welcomeBack,
                                    style: GoogleFonts.jost(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    t.tagline,
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      height: 1.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            GlassCard(
                              padding: const EdgeInsets.all(24),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      t.logIn,
                                      style: GoogleFonts.jost(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    TextFormField(
                                      focusNode: _emailFocusNode,
                                      controller: _emailCtrl,
                                      decoration: InputDecoration(
                                        labelText: t.email,
                                        prefixIcon: const Icon(
                                          Icons.email_outlined,
                                        ),
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      textCapitalization:
                                          TextCapitalization.none,
                                      validator: (v) => (v == null || v.isEmpty)
                                          ? t.emailRequired
                                          : null,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      focusNode: _passwordFocusNode,
                                      controller: _passwordCtrl,
                                      decoration: InputDecoration(
                                        labelText: t.password,
                                        prefixIcon: const Icon(
                                          Icons.lock_outline,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscure
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                          ),
                                          onPressed: () => setState(
                                            () => _obscure = !_obscure,
                                          ),
                                        ),
                                      ),
                                      obscureText: _obscure,
                                      textInputAction: TextInputAction.done,
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      validator: (v) => (v == null || v.isEmpty)
                                          ? t.passwordRequired
                                          : null,
                                      onFieldSubmitted: (_) => _submit(),
                                    ),
                                    const SizedBox(height: 24),
                                    GradientButton(
                                      onPressed: authState.isLoading
                                          ? null
                                          : _submit,
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
                                          : Text(t.logIn),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextButton(
                              onPressed: () => context.push('/register'),
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
                  ),
                ),
              ),
        ),
      ),
    );
  }
}
