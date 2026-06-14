import 'package:flutter/material.dart';
import 'package:voyanz/core/theme/app_colors.dart';

/// Restrained gradients used for brand moments and selected states.
abstract final class AppGradients {
  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF8FB), AppColors.canvas, Color(0xFFF4FBFD)],
    stops: [0.0, 0.52, 1.0],
  );

  static const background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF9FC), AppColors.canvas, Color(0xFFFFFFFF)],
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
    colors: [Color(0xFFFFEDF5), Color(0xFFF1EEFF), Color(0x00FFFFFF)],
    stops: [0.0, 0.58, 1.0],
  );

  static const headerNavbar = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFAFFFFFF), Color(0xEEFFFFFF)],
  );

  static const card = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFFBFAFF), Color(0xFFF8FCFF)],
    stops: [0.0, 0.62, 1.0],
  );

  static const surfaceGlow = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0x147C5CE0), Color(0x1010B8C4)],
  );
}
