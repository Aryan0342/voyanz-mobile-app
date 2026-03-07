import 'package:flutter/material.dart';
import 'package:voyanz/core/theme/app_colors.dart';

/// Reusable gradient definitions matching voyanz.com.
abstract final class AppGradients {
  /// Hero section gradient — dark indigo to magenta rose.
  static const hero = LinearGradient(
    begin: Alignment(-0.6, -0.8),
    end: Alignment(0.8, 0.8),
    colors: [AppColors.darkPurple, AppColors.deepIndigo, AppColors.magentaRose],
    stops: [0.0, 0.05, 1.0],
  );

  /// Primary accent gradient — rose pink to medium purple.
  static const accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.rosePink, AppColors.mediumPurple],
  );

  /// Subtle dark background gradient for screens.
  static const background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.deepIndigo, AppColors.darkPurple],
  );

  /// Card shimmer gradient.
  static const card = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.surfaceCard, AppColors.surfaceElevated],
  );
}
