import 'dart:ui';

import 'package:flutter/material.dart';

abstract final class GlassTheme {
  static const Color background = Color(0xFF100B2E);
  static const Color crystalWhite = Color(0xFF171039);
  static const Color glassSurface = Color(0xE6211747);
  static const Color glassOverlay = Color(0xE62A1D55);
  static const Color glassSubtle = Color(0xD9171039);

  static const Color purpleLight = Color(0xFFFF43BD);
  static const Color purpleMid = Color(0xFFD23E91);
  static const Color purpleDark = Color(0xFF7541A9);

  static const Color textPrimary = Color(0xFFFDFBFF);
  static const Color textSecondary = Color(0xFFD9D1E8);
  static const Color textTertiary = Color(0xFFA99DBD);
  static const Color textInverse = Color(0xFFFFFFFF);

  static const Color borderLight = Color(0x66443469);
  static const Color borderGlass = Color(0x5269528F);
  static const Color divider = Color(0x52443469);
  static const Color shadowGlow = Color(0x335C2B63);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0;
  static const double radiusXL = 24.0;

  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;

  static const double glassBlurSigma = 24.0;
  static const double glassBlurSigmaDeep = 40.0;

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [purpleDark, purpleLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient purpleRadialGradient = RadialGradient(
    colors: [Color(0x809B3366), Color(0x005C2B63)],
    center: Alignment.center,
    radius: 0.85,
  );

  static const LinearGradient softWhiteGradient = LinearGradient(
    colors: [Color(0xF02B1C54), Color(0xE6172044)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const BoxShadow shadowSmall = BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 12,
    offset: Offset(0, 6),
  );

  static const BoxShadow shadowMedium = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 18,
    offset: Offset(0, 10),
  );

  static const BoxShadow shadowLarge = BoxShadow(
    color: Color(0x1D000000),
    blurRadius: 28,
    offset: Offset(0, 16),
  );

  static const BoxShadow glowPurple = BoxShadow(
    color: shadowGlow,
    blurRadius: 34,
    spreadRadius: 3,
  );

  static TextStyle _style(
    double fontSize,
    FontWeight fontWeight,
    Color color, {
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: 'SF Pro Display',
      fontFamilyFallback: const ['Inter', 'Segoe UI', 'Roboto', 'Arial'],
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle get displayLarge =>
      _style(48, FontWeight.w700, textPrimary, letterSpacing: 0);

  static TextStyle get displayMedium =>
      _style(40, FontWeight.w700, textPrimary, letterSpacing: 0);

  static TextStyle get headingXL =>
      _style(32, FontWeight.w700, textPrimary, letterSpacing: 0);

  static TextStyle get headingLarge =>
      _style(28, FontWeight.w700, textPrimary, letterSpacing: 0);

  static TextStyle get headingMedium =>
      _style(24, FontWeight.w600, textPrimary);

  static TextStyle get headingSmall => _style(20, FontWeight.w600, textPrimary);

  static TextStyle get bodyLarge =>
      _style(16, FontWeight.w500, textSecondary, height: 1.5);

  static TextStyle get bodyMedium =>
      _style(14, FontWeight.w400, textSecondary, height: 1.5);

  static TextStyle get bodySmall =>
      _style(12, FontWeight.w400, textTertiary, height: 1.4);

  static TextStyle get labelLarge => _style(16, FontWeight.w600, textInverse);

  static TextStyle get labelMedium => _style(14, FontWeight.w600, textInverse);

  static TextStyle get captionSmall =>
      _style(11, FontWeight.w500, textTertiary, letterSpacing: 0);
}
