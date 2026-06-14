import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:voyanz/core/theme/glass_theme.dart';
import 'package:voyanz/widgets/glass_components.dart';

class CrystalHomeScreen extends StatefulWidget {
  const CrystalHomeScreen({super.key});

  @override
  State<CrystalHomeScreen> createState() => _CrystalHomeScreenState();
}

class _CrystalHomeScreenState extends State<CrystalHomeScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassTheme.background,
      body: Stack(
        children: [
          const _CrystalBackground(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(onMenuTap: () {}),
                  const SizedBox(height: 24),
                  const _HeroSection(),
                  const SizedBox(height: 28),
                  const GlassSectionHeader(
                    title: 'Services cristallins',
                    subtitle:
                        'Une expérience mobile claire, rapide et élégante inspirée du luxe discret de Voyanz.',
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.78,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      GlassServiceCard(
                        icon: Icons.auto_awesome_rounded,
                        title: 'Crystal UI',
                        description:
                            'Cartes flottantes, reflets doux et profondeur propre.',
                      ),
                      GlassServiceCard(
                        icon: Icons.speed_rounded,
                        title: 'Fast Flow',
                        description:
                            'Un parcours visuel fluide avec hiérarchie claire.',
                      ),
                      GlassServiceCard(
                        icon: Icons.shield_rounded,
                        title: 'Trust Layer',
                        description:
                            'Typographie nette, contraste élevé et surfaces lisibles.',
                      ),
                      GlassServiceCard(
                        icon: Icons.view_in_ar_rounded,
                        title: 'Responsive',
                        description:
                            'Une mise en page adaptative pensée pour le mobile.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const GlassSectionHeader(
                    title: 'Statistiques',
                    subtitle:
                        'Des données présentées dans des barres cristallines simples à scanner.',
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.02,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      GlassStatCard(
                        value: '120K',
                        label: 'Utilisateurs actifs',
                        accent: GlassTheme.purpleDark,
                      ),
                      GlassStatCard(
                        value: '98%',
                        label: 'Satisfaction',
                        accent: Color(0xFFEC4899),
                      ),
                      GlassStatCard(
                        value: '24 ms',
                        label: 'Temps perçu',
                        accent: Color(0xFF6366F1),
                      ),
                      GlassStatCard(
                        value: '4.9',
                        label: 'Note moyenne',
                        accent: Color(0xFF8B5CF6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const GlassSectionHeader(
                    title: 'Case studies',
                    subtitle:
                        'Des compositions visuelles riches avec overlays en verre et transitions subtiles.',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 304,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final data = _caseStudies[index];
                        return SizedBox(
                          width: 284,
                          child: GlassCaseStudyCard(
                            title: data.$1,
                            description: data.$2,
                            tag: data.$3,
                            gradient: data.$4,
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemCount: _caseStudies.length,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const GlassSectionHeader(
                    title: 'À propos',
                    subtitle:
                        'Une interface claire avec beaucoup d’air, des alignements propres et une lecture immédiate.',
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _AboutRow(
                          icon: Icons.layers_rounded,
                          title: 'Structure nette',
                          description:
                              'Sections espacées, blocs bien hiérarchisés et contours légers.',
                        ),
                        SizedBox(height: 18),
                        _AboutRow(
                          icon: Icons.blur_on_rounded,
                          title: 'Verre discret',
                          description:
                              'Blurs souples, reflets fins et ombres diffuses pour une profondeur élégante.',
                        ),
                        SizedBox(height: 18),
                        _AboutRow(
                          icon: Icons.text_fields_rounded,
                          title: 'Typographie premium',
                          description:
                              'SF Pro / Inter avec une hiérarchie stricte pour un rendu lisible.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  GlassCard(
                    withGlow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prêt à passer au cristal ?',
                          style: GlassTheme.headingLarge,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Une landing mobile élégante, modulaire et pensée pour mettre les cartes et les CTA au premier plan.',
                          style: GlassTheme.bodyLarge,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: GlassButton.primary(
                                label: 'Commencer',
                                icon: Icons.bolt_rounded,
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: CrystalBottomBar(
            currentIndex: _currentTab,
            onChanged: (index) => setState(() => _currentTab = index),
          ),
        ),
      ),
    );
  }

  static const List<(String, String, String, LinearGradient)> _caseStudies = [
    (
      'Voyanz Mobile Revamp',
      'Exploration d’une interface fluide pour attirer l’attention dès le premier écran.',
      'Brand',
      LinearGradient(
        colors: [Color(0xFF7B61FF), Color(0xFFA78BFA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    (
      'Crystal Booking Flow',
      'Cartes, overlays et hiérarchie visuelle pour une expérience plus premium.',
      'UX',
      LinearGradient(
        colors: [Color(0xFF1D4ED8), Color(0xFF7C3AED)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    (
      'Consultation Dashboard',
      'Un tableau de bord doux, lisible et orienté contenu plutôt que décor.',
      'Product',
      LinearGradient(
        colors: [Color(0xFF0F172A), Color(0xFF8B5CF6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ];
}

class _CrystalBackground extends StatelessWidget {
  const _CrystalBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: GlassTheme.background),
        Positioned(
          top: -90,
          right: -70,
          child: _Orb(size: 220, gradient: GlassTheme.purpleRadialGradient),
        ),
        Positioned(
          top: 180,
          left: -70,
          child: _Orb(
            size: 160,
            gradient: RadialGradient(
              colors: [Colors.pinkAccent.withOpacity(0.14), Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.gradient});

  final double size;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
      foregroundDecoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: GlassTheme.purpleMid.withOpacity(0.14),
            blurRadius: 72,
            spreadRadius: 14,
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onMenuTap});

  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          radius: 18,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: GlassTheme.purpleGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text('Voyanz', style: GlassTheme.headingSmall),
            ],
          ),
        ),
        const Spacer(),
        GlassCard(
          padding: const EdgeInsets.all(12),
          radius: 18,
          child: GestureDetector(
            onTap: onMenuTap,
            child: const Icon(
              Icons.menu_rounded,
              color: GlassTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      withGlow: true,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: GlassTheme.purpleMid.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: GlassTheme.borderLight),
                      ),
                      child: Text(
                        'Voyanz',
                        style: GlassTheme.captionSmall.copyWith(
                          color: GlassTheme.purpleDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Live guidance\nwith trusted professionals',
                      style: GlassTheme.displayMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Connect with the right expert, start a session, and keep every conversation in one calm workspace.',
                      style: GlassTheme.bodyLarge,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: GlassButton.primary(
                            label: 'Explore design',
                            icon: Icons.arrow_forward_rounded,
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: AspectRatio(
                  aspectRatio: 0.78,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: GlassTheme.purpleRadialGradient,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: GlassTheme.glassBlurSigmaDeep,
                            sigmaY: GlassTheme.glassBlurSigmaDeep,
                          ),
                          child: const SizedBox.shrink(),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        top: 18,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.22),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 14,
                        bottom: 18,
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.28),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        right: 18,
                        bottom: 18,
                        child: GlassCard(
                          radius: 22,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Crystal bar', style: GlassTheme.bodySmall),
                              const SizedBox(height: 8),
                              Text(
                                'Soft glow · 24px blur · clean spacing',
                                style: GlassTheme.bodyLarge,
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
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: GlassTheme.purpleMid.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: GlassTheme.purpleDark, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GlassTheme.headingSmall),
              const SizedBox(height: 4),
              Text(description, style: GlassTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
