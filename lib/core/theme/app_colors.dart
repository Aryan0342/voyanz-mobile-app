import 'package:flutter/material.dart';

/// Voyanz brand color palette — derived from voyanz.com.
abstract final class AppColors {
  // ── Primary dark backgrounds ──
  static const deepIndigo = Color(0xFF0D094C);
  static const darkPurple = Color(0xFF1D193E);
  static const darkOverlay = Color(0xFF2A1F3D);

  // ── Accent colors ──
  static const rosePink = Color(0xFFF5A8C4);
  static const mediumPurple = Color(0xFF9370DB);
  static const magentaRose = Color(0xFF9B3366);

  // ── Surface / card shades ──
  static const surfaceDark = Color(0xFF160F36);
  static const surfaceCard = Color(0xFF1E1848);
  static const surfaceElevated = Color(0xFF261E52);
  static const surfaceLight = Color(0xFF2D2458);
  static const borderSubtle = Color(0xFF3D3366);

  // ── Text ──
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB8B0D4);
  static const textMuted = Color(0xFF7E75A3);

  // ── Semantic ──
  static const success = Color(0xFF4ADE80);
  static const error = Color(0xFFFF6B6B);
  static const warning = Color(0xFFFFD93D);
  static const info = Color(0xFF93C5FD);

  // ── Online indicator ──
  static const online = Color(0xFF4ADE80);
  static const offline = Color(0xFF64748B);
}
