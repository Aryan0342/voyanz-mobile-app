import 'package:flutter/material.dart';
import 'package:voyanz/core/theme/app_colors.dart';

/// Reusable gradient definitions matching voyanz.com.
abstract final class AppGradients {
  /// Hero section gradient.
  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFDFDFF), Color(0xFFF7F5FF)],
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
    colors: [Color(0xFFFFFFFF), Color(0xFFFDFDFF), Color(0xFFF8F7FC)],
    stops: [0.0, 0.58, 1.0],
  );

  /// Header tint used behind top titles/app bars on light screens.
  static const headerTint = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x0D7B61FF), Color(0x08A78BFA), Color(0x00FFFFFF)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Website-like navbar/header gradient from voyanz.com.
  static const headerNavbar = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xEFFFFFFF), Color(0xDFFFFFFF)],
  );

  /// Card shimmer gradient.
  static const card = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xCCFFFFFF), Color(0xF7FAFBFF)],
  );

  /// Surface glow accent for chips/pills/active states.
  static const surfaceGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x147B61FF), Color(0x10A78BFA)],
  );

  /// CTA gradient variant used for primary hero actions.
  static const cta = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF7B61FF), Color(0xFFA78BFA)],
  );
}
