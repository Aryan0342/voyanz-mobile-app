import 'package:flutter/material.dart';
import 'package:voyanz/core/theme/app_colors.dart';

/// Reusable gradient definitions matching voyanz.com.
abstract final class AppGradients {
  /// Hero section gradient.
  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8F5FD), Color(0xFFF2ECFB)],
  );

  /// Primary accent gradient — rose pink to medium purple.
  static const accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.rosePink, Color(0xFFB18AE8)],
  );

  /// Subtle light background gradient for screens.
  static const background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFDFF), Color(0xFFF8F4FD), Color(0xFFF3EEFA)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Header tint used behind top titles/app bars on light screens.
  static const headerTint = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x1F9370DB), Color(0x14F5A8C4), Color(0x00FFFFFF)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Website-like navbar/header gradient from voyanz.com.
  static const headerNavbar = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF240046), Color(0xFF0D1124)],
  );

  /// Card shimmer gradient.
  static const card = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF9F6FE)],
  );

  /// Surface glow accent for chips/pills/active states.
  static const surfaceGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x1FF5A8C4), Color(0x1A9370DB)],
  );

  /// CTA gradient variant used for primary hero actions.
  static const cta = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFF3A6C3), Color(0xFFB78FEA)],
  );
}
