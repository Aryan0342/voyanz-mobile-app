import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';

/// A gradient-filled button used as the primary CTA throughout the app.
class GradientButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.width,
    this.height = 52,
    this.borderRadius,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(18);
    final enabled = widget.onPressed != null;

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      scale: _pressed ? 0.985 : 1,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled ? 1 : 0.64,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: enabled
                  ? AppGradients.cta
                  : const LinearGradient(
                      colors: [AppColors.surfaceLight, AppColors.surfaceLight],
                    ),
              borderRadius: radius,
              border: Border.all(
                color: AppColors.borderSubtle.withValues(
                  alpha: enabled ? 0.18 : 0.5,
                ),
              ),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppColors.mediumPurple.withValues(alpha: 0.24),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: AppColors.magentaRose.withValues(alpha: 0.10),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                onTapDown: enabled ? (_) => _setPressed(true) : null,
                onTapCancel: enabled ? () => _setPressed(false) : null,
                onTapUp: enabled ? (_) => _setPressed(false) : null,
                borderRadius: radius,
                child: Center(
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: 0,
                    ),
                    child: widget.child,
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

/// A polished surface container for cards and panels.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(20);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
      builder: (context, value, builtChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: Transform.scale(
              scale: 0.985 + (0.015 * value),
              child: builtChild,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: AppColors.deepIndigo.withValues(alpha: 0.07),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: AppColors.mediumPurple.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: padding ?? const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppGradients.card,
                borderRadius: radius,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared app bar shell used across feature screens.
class VoyanzAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final Widget? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool centerTitle;
  final double toolbarHeight;

  const VoyanzAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
    this.centerTitle = false,
    this.toolbarHeight = kToolbarHeight,
  });

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  void _handleBack(BuildContext context) {
    if (onBackPressed != null) {
      onBackPressed!();
      return;
    }

    if (context.canPop()) {
      context.pop();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTitle = title == null
        ? null
        : subtitle == null
        ? title
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [title!, const SizedBox(height: 2), subtitle!],
          );

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      centerTitle: centerTitle,
      toolbarHeight: toolbarHeight,
      titleSpacing: 16,
      leadingWidth: showBackButton ? 62 : null,
      leading:
          leading ??
          (showBackButton
              ? Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: VoyanzAppBarIconButton(
                    icon: Icons.arrow_back_ios_new,
                    onPressed: () => _handleBack(context),
                    iconSize: 18,
                  ),
                )
              : null),
      title: effectiveTitle,
      actions: actions,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              gradient: AppGradients.headerNavbar,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.borderSubtle,
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular icon button used in shared app bars.
class VoyanzAppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double iconSize;
  final EdgeInsetsGeometry padding;

  const VoyanzAppBarIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.iconSize = 20,
    this.padding = const EdgeInsets.all(10),
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(14);
    final button = Material(
      color: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      elevation: 2,
      shadowColor: AppColors.deepIndigo.withValues(alpha: 0.10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: borderRadius,
        child: Padding(
          padding: padding,
          child: Icon(icon, size: iconSize, color: AppColors.textPrimary),
        ),
      ),
    );

    if (tooltip == null) {
      return button;
    }

    return Tooltip(message: tooltip!, child: button);
  }
}

/// A gradient scaffold background — wraps child in the app's premium shell.
class GradientScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const GradientScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
          child: IgnorePointer(
                child: Container(
                  height: 156,
                  decoration: const BoxDecoration(
                    gradient: AppGradients.headerTint,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        AppColors.rosePink.withValues(alpha: 0.06),
                        Colors.transparent,
                        AppColors.aqua.withValues(alpha: 0.035),
                      ],
                      stops: const [0.0, 0.48, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            body,
          ],
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, value, builtChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - value)),
            child: builtChild,
          ),
        );
      },
      child: Material(
        color: AppColors.surfaceCard,
        borderRadius: radius,
        elevation: 2,
        shadowColor: AppColors.deepIndigo.withValues(alpha: 0.08),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
              gradient: AppGradients.card,
              boxShadow: [
                BoxShadow(
                  color: AppColors.mediumPurple.withValues(alpha: 0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class SoftEntrance extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Offset offset;

  const SoftEntrance({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 320),
    this.offset = const Offset(0, 10),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, builtChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(offset.dx * (1 - value), offset.dy * (1 - value)),
            child: Transform.scale(
              scale: 0.99 + (0.01 * value),
              child: builtChild,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class SoftPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const SoftPress({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
  });

  @override
  State<SoftPress> createState() => _SoftPressState();
}

class _SoftPressState extends State<SoftPress> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(18);
    final enabled = widget.onTap != null;

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      scale: _pressed ? 0.985 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          borderRadius: radius,
          child: widget.child,
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
