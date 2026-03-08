import 'package:flutter/material.dart';
import 'package:voyanz/core/theme/app_colors.dart';

/// Reusable gradient definitions matching voyanz.com.
abstract final class AppGradients {
  /// Hero section gradient — refined dark purple.
  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.deepIndigo, AppColors.darkPurple],
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
