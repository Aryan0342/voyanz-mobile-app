import 'package:flutter/material.dart';

/// Voyanz palette shared by the website and mobile products.
abstract final class AppColors {
  // Brand anchors
  static const deepIndigo = Color(0xFF0D094C);
  static const darkPurple = Color(0xFF1D193E);
  static const darkOverlay = Color(0xFF251D4B);
  static const brandPink = Color(0xFFFF43BD);

  // Accents
  static const rosePink = Color(0xFFFFA7D8);
  static const mediumPurple = Color(0xFF7541A9);
  static const brandMagenta = Color(0xFFD23E91);
  static const magentaRose = Color(0xFFD23E91);
  static const aqua = Color(0xFF12C8D4);
  static const gold = Color(0xFFF59E0B);

  // Surfaces
  static const canvas = Color(0xFF100B2E);
  static const surfaceDark = Color(0xFF171039);
  static const surfaceCard = Color(0xFF211747);
  static const surfaceElevated = Color(0xFF2A1D55);
  static const surfaceLight = Color(0xFF362760);
  static const surfaceHeader = Color(0xF2161039);
  static const borderSubtle = Color(0xFF443469);
  static const borderStrong = Color(0xFF69528F);

  // Text
  static const textPrimary = Color(0xFFFDFBFF);
  static const textSecondary = Color(0xFFD9D1E8);
  static const textMuted = Color(0xFFA99DBD);

  // Semantic
  static const success = Color(0xFF16A34A);
  static const error = Color(0xFFDC2626);
  static const warning = Color(0xFFD97706);
  static const info = Color(0xFF2563EB);

  // Presence
  static const online = Color(0xFF4ADE80);
  static const offline = Color(0xFF64748B);
}
