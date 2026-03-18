import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.loginFailed(next.error.toString()))),
        );
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.hero),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Logo / Brand ──
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: brandPrimary.withValues(alpha: 0.2),
                              blurRadius: 32,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: (logo != null && logo.isNotEmpty)
                            ? Image.network(
                                logo,
                                width: 100,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/images/voyanz-logo.png',
                                  width: 100,
                                  fit: BoxFit.contain,
                                ),
                              )
                            : Image.asset(
                                'assets/images/voyanz-logo.png',
                                width: 100,
                                fit: BoxFit.contain,
                              ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        (agencyName != null && agencyName.isNotEmpty)
                            ? agencyName
                            : 'Voyanz',
                        style: GoogleFonts.jost(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: brandPrimary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.tagline,
                        style: GoogleFonts.lora(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // ── Glass Card Login Form ──
                      GlassCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                t.welcomeBack,
                                style: GoogleFonts.jost(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _emailCtrl,
                                decoration: InputDecoration(
                                  labelText: t.email,
                                  prefixIcon: const Icon(Icons.email_outlined),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? t.emailRequired
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordCtrl,
                                decoration: InputDecoration(
                                  labelText: t.password,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? t.passwordRequired
                                    : null,
                                onFieldSubmitted: (_) => _submit(),
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
                                    : Text(t.logIn),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: Text.rich(
                          TextSpan(
                            text: t.noAccount,
                            style: GoogleFonts.montserrat(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: t.signUp,
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
      ),
    );
  }
}
