import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const Duration _enterDuration = Duration(milliseconds: 1200);

  @override
  void initState() {
    super.initState();
    _goNext();
  }

  Future<void> _goNext() async {
    await Future<void>.delayed(_enterDuration);
    final isLoggedIn = await ref
        .read(authStateProvider.notifier)
        .restoreSession();
    if (!mounted) return;
    context.go(isLoggedIn ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.hero),
        child: Stack(
          children: [
            const Positioned(
              top: -60,
              right: -36,
              child: _GlowBlob(
                size: 180,
                colors: [AppColors.rosePink, Color(0x00F5A8C4)],
              ),
            ),
            const Positioned(
              left: -48,
              bottom: 120,
              child: _GlowBlob(
                size: 210,
                colors: [AppColors.mediumPurple, Color(0x009370DB)],
              ),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 34,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.92),
                            AppColors.surfaceElevated.withValues(alpha: 0.86),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: AppColors.borderSubtle.withValues(alpha: 0.8),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.deepIndigo.withValues(alpha: 0.08),
                            blurRadius: 34,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 104,
                            height: 104,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppGradients.accent,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.mediumPurple.withValues(
                                    alpha: 0.22,
                                  ),
                                  blurRadius: 24,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/voyanz-logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Voyanz',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.jost(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Real-time sessions and expert guidance',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              height: 1.45,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 28),
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: AppColors.mediumPurple,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Preparing your experience',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _GlowBlob({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}
