import 'package:flutter/material.dart';

/// Voyanz brand color palette — derived from voyanz.com.
abstract final class AppColors {
  // ── Brand base / anchors ──
  static const deepIndigo = Color(0xFF0D094C);
  static const darkPurple = Color(0xFF1D193E);
  static const darkOverlay = Color(0xFF2A1F3D);

  // ── Accent colors ──
  static const rosePink = Color(0xFFF5A8C4);
  static const mediumPurple = Color(0xFF9370DB);
  static const magentaRose = Color(0xFF9B3366);

  // ── Light surface / card shades ──
  static const surfaceDark = Color(0xFFF4F1FA);
  static const surfaceCard = Color(0xFFFFFFFF);
  static const surfaceElevated = Color(0xFFF8F6FD);
  static const surfaceLight = Color(0xFFF2EEFA);
  static const surfaceHeader = Color(0xFFC3B0E6);
  static const borderSubtle = Color(0xFFD9D0EC);

  // ── Text on light surfaces ──
  static const textPrimary = Color(0xFF19142C);
  static const textSecondary = Color(0xFF5F547E);
  static const textMuted = Color(0xFF867AA7);

  // ── Semantic ──
  static const success = Color(0xFF16A34A);
  static const error = Color(0xFFDC2626);
  static const warning = Color(0xFFEAB308);
  static const info = Color(0xFF93C5FD);

  // ── Online indicator ──
  static const online = Color(0xFF4ADE80);
  static const offline = Color(0xFF64748B);
}
