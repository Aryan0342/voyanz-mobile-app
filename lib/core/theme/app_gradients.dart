import 'package:flutter/material.dart';
import 'package:voyanz/core/theme/app_colors.dart';

/// Restrained gradients used for brand moments and selected states.
abstract final class AppGradients {
  static const brandBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.darkPurple, AppColors.deepIndigo, Color(0xFF4F174F)],
    stops: [0.0, 0.05, 1.0],
  );

  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF32164C), AppColors.canvas, Color(0xFF111E43)],
    stops: [0.0, 0.52, 1.0],
  );

  static const background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF21103F), AppColors.canvas, Color(0xFF0C1533)],
    stops: [0.0, 0.42, 1.0],
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
    colors: [Color(0xAA552052), Color(0x55251D4B), Color(0x00100B2E)],
    stops: [0.0, 0.58, 1.0],
  );

  static const headerNavbar = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xF5161039), Color(0xED100B2E)],
  );

  static const card = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2B1C54), Color(0xFF211747), Color(0xFF182044)],
    stops: [0.0, 0.62, 1.0],
  );

  static const surfaceGlow = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0x557541A9), Color(0x44D23E91)],
  );
}
