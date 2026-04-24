import 'package:flutter/material.dart';
import 'package:voyanz/core/theme/app_colors.dart';

/// Reusable gradient definitions matching voyanz.com.
abstract final class AppGradients {
  /// Hero section gradient — refined dark purple.
  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF120E5A), AppColors.darkPurple],
  );

  /// Primary accent gradient — rose pink to medium purple.
  static const accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.rosePink, Color(0xFFB18AE8)],
  );

  /// Subtle dark background gradient for screens.
  static const background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0C0948), Color(0xFF1A1447), Color(0xFF130E35)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Card shimmer gradient.
  static const card = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF241C59), Color(0xFF1D164A)],
  );

  /// Surface glow accent for chips/pills/active states.
  static const surfaceGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x33F5A8C4), Color(0x269370DB)],
  );

  /// CTA gradient variant used for primary hero actions.
  static const cta = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFF3A6C3), Color(0xFFB78FEA)],
  );
}
