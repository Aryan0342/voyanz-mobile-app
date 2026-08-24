import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/l10n/language_switcher.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _emailFocusNode = FocusNode();
  bool _submitting = false;

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final t = ref.read(translationsProvider);
    setState(() => _submitting = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .forgetPassword(email: _emailCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.resetLinkSent)),
      );
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      final message = e
          .toString()
          .replaceFirst(RegExp(r'^Exception:\s*', caseSensitive: false), '')
          .trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().toLowerCase().contains('not_found')
                ? t.noAccountWithEmail
                : t.resetLinkFailed(message),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // HERO SECTION
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppGradients.brandBackground,
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => context.go('/login'),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                        ),
                        LanguageSwitcherButton(),
                      ],
                    ),
                    Center(
                      child: Image.asset(
                        'assets/images/voyanz-mark.png',
                        width: 64,
                        fit: BoxFit.contain,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // FORM CARD
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
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
                          Text(
                            t.forgotPassword,
                            style: GoogleFonts.jost(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t.resetPasswordSubtitle,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 26),

                          // Email field
                          TextFormField(
                            controller: _emailCtrl,
                            focusNode: _emailFocusNode,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            autocorrect: false,
                            enableSuggestions: false,
                            textCapitalization: TextCapitalization.none,
                            onFieldSubmitted: (_) => _submit(),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? t.emailRequired : null,
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: t.email,
                              hintStyle: GoogleFonts.manrope(
                                color: AppColors.textMuted,
                                fontSize: 15,
                              ),
                              prefixIcon: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 14),
                                child: Icon(
                                  Icons.email_outlined,
                                  color: AppColors.textMuted,
                                  size: 20,
                                ),
                              ),
                              prefixIconConstraints:
                                  const BoxConstraints(minWidth: 52),
                              filled: true,
                              fillColor: const Color(0xFFF4F5F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE4E6EF),
                                  width: 1.2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE4E6EF),
                                  width: 1.2,
                                ),
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
                                borderSide: const BorderSide(
                                  color: AppColors.error,
                                  width: 1.2,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: AppColors.error,
                                  width: 1.6,
                                ),
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // CTA Button
                          GradientButton(
                            onPressed: _submitting ? null : _submit,
                            width: double.infinity,
                            height: 56,
                            borderRadius: BorderRadius.circular(32),
                            child: _submitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    t.sendResetLink,
                                    style: GoogleFonts.jost(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 24),

                          // Back to login
                          Center(
                            child: TextButton(
                              onPressed: () => context.go('/login'),
                              child: Text(
                                t.backToLogin,
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.magentaRose,
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
    );
  }
}
