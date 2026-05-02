import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:voyanz/core/theme/glass_theme.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = GlassTheme.radiusXL,
    this.withGlow = false,
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool withGlow;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          GlassTheme.shadowSmall,
          if (withGlow) GlassTheme.glowPurple,
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GlassTheme.glassBlurSigma,
            sigmaY: GlassTheme.glassBlurSigma,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: GlassTheme.softWhiteGradient,
              color: GlassTheme.glassSurface,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: GlassTheme.borderGlass),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class GlassButton extends StatefulWidget {
  const GlassButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : outlined = false;

  const GlassButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : outlined = true;

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool outlined;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final content = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 17),
            const SizedBox(width: 8),
          ],
          Text(widget.label, style: GlassTheme.labelLarge),
        ],
      ),
    );

    final button = AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          onHighlightChanged: (value) => setState(() => _pressed = value),
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              gradient: widget.outlined ? null : GlassTheme.purpleGradient,
              color: widget.outlined ? GlassTheme.glassOverlay : null,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: widget.outlined
                    ? GlassTheme.borderLight
                    : GlassTheme.borderGlass,
              ),
              boxShadow: [
                if (!widget.outlined) GlassTheme.glowPurple,
                GlassTheme.shadowSmall,
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: content,
          ),
        ),
      ),
    );

    return button;
  }
}

class GlassSectionHeader extends StatelessWidget {
  const GlassSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.centered = false,
  });

  final String title;
  final String? subtitle;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: GlassTheme.headingLarge,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: GlassTheme.bodyLarge,
          ),
        ],
      ],
    );
  }
}

class GlassServiceCard extends StatelessWidget {
  const GlassServiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: GlassTheme.purpleGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [GlassTheme.glowPurple],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GlassTheme.headingSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GlassTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class GlassStatCard extends StatelessWidget {
  const GlassStatCard({
    super.key,
    required this.value,
    required this.label,
    this.accent = GlassTheme.purpleMid,
  });

  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent.withOpacity(0.85), accent.withOpacity(0.2)],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GlassTheme.displayLarge.copyWith(
              color: accent,
              fontSize: 30,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GlassTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class GlassCaseStudyCard extends StatefulWidget {
  const GlassCaseStudyCard({
    super.key,
    required this.title,
    required this.description,
    required this.gradient,
    required this.tag,
  });

  final String title;
  final String description;
  final LinearGradient gradient;
  final String tag;

  @override
  State<GlassCaseStudyCard> createState() => _GlassCaseStudyCardState();
}

class _GlassCaseStudyCardState extends State<GlassCaseStudyCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        child: GlassCard(
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 280,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: widget.gradient),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.05),
                          Colors.black.withOpacity(0.18),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 18,
                  left: 18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.35)),
                    ),
                    child: Text(
                      widget.tag,
                      style: GlassTheme.captionSmall.copyWith(
                        color: Colors.white,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -18,
                  top: -12,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.22),
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 18,
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    radius: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: GlassTheme.headingSmall),
                        const SizedBox(height: 6),
                        Text(widget.description, style: GlassTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CrystalBottomBar extends StatelessWidget {
  const CrystalBottomBar({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'Home'),
      (Icons.grid_view_rounded, 'Services'),
      (Icons.query_stats_rounded, 'Stats'),
      (Icons.photo_library_rounded, 'Cases'),
      (Icons.person_rounded, 'About'),
    ];

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final selected = index == currentIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? GlassTheme.purpleMid.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.$1,
                      size: 22,
                      color: selected
                          ? GlassTheme.purpleDark
                          : GlassTheme.textTertiary,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.$2,
                      style: GlassTheme.captionSmall.copyWith(
                        color: selected
                            ? GlassTheme.purpleDark
                            : GlassTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
