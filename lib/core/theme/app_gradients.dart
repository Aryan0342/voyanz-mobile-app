import 'package:flutter/material.dart';
import 'package:voyanz/core/theme/app_colors.dart';

/// Restrained gradients used for brand moments and selected states.
abstract final class AppGradients {
  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.canvas, Color(0xFFFFFFFF)],
  );

  static const background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.canvas, Color(0xFFFFFFFF)],
  );

  static const accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.mediumPurple, AppColors.magentaRose],
  );

  static const cta = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.mediumPurple, AppColors.magentaRose],
  );

  static const headerTint = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF4F0FF), Color(0x00FFFFFF)],
  );

  static const headerNavbar = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFAFFFFFF), Color(0xEEFFFFFF)],
  );

  static const card = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.surfaceCard, AppColors.surfaceElevated],
  );

  static const surfaceGlow = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0x147C5CE0), Color(0x1010B8C4)],
  );
}
