import 'package:flutter/material.dart';

/// Cyber-Modern IT Support – Stitch Design System
class AppColors {
  AppColors._();

  // — Brand ————————————————————————————————————————
  static const Color primary           = Color(0xFFBEC6E8);
  static const Color onPrimary         = Color(0xFF283044);
  static const Color primaryContainer  = Color(0xFF8F172A);
  static const Color secondary          = Color(0xFFADC6FF);
  static const Color secondaryContainer = Color(0xFF566009);

  // — Accent ———————————————————————————————————————
  static const Color tertiary             = Color(0xFF2FD9F4);
  static const Color tertiaryDim          = Color(0xFF2FD9F4);
  static const Color tertiaryContainer    = Color(0xFF001820);
  static const Color onTertiaryContainer  = Color(0xFF968EA1);

  // — Surfaces —————————————————————————————————————
  static const Color background              = Color(0xFF0F172A);
  static const Color surface                 = Color(0xFF101415);
  static const Color surfaceContainerLowest  = Color(0xFF080F10);
  static const Color surfaceContainerLow     = Color(0xFF191C1E);
  static const Color surfaceContainer        = Color(0xFF102022);
  static const Color surfaceContainerHigh    = Color(0xFF272A2C);
  static const Color surfaceContainerHighest = Color(0xFF323537);
  static const Color surfaceBright           = Color(0xFF363A3B);

  // — Text —————————————————————————————————————————
  static const Color onSurface        = Color(0xFFE0E3E5);
  static const Color onSurfaceVariant = Color(0xFFC6C0C0);
  static const Color outline          = Color(0xFF909097);
  static const Color outlineVariant   = Color(0xFF45464D);

  // — Semantic —————————————————————————————————————
  static const Color error          = Color(0xFFFFB4A8);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color success        = Color(0xFF2FD9F4);
  static const Color warning        = Color(0xFFFFB740);

  // — Priority —————————————————————————————————————
  static const Color priorityUrgent = Color(0xFFFF5449);
  static const Color priorityHigh   = Color(0xFFFFB740);
  static const Color priorityMedium = Color(0xFFADC6FF);
  static const Color priorityLow    = Color(0xFF909097);

  // — Glass ————————————————————————————————————————
  static Color glassCard   = const Color(0xFF102022).withValues(alpha: 0.7);
  static Color glassBorder = Colors.white.withValues(alpha: 0.1);
  static Color cyanGlow    = const Color(0xFF2FD9F4).withValues(alpha: 0.15);

  // — Legacy Light Theme ———————————————————————————
  static const Color lightSurface       = Color(0xFFFFFFFF);
  static const Color lightBackground    = Color(0xFFF5F5F5);
  static const Color lightCard          = Color(0xFFFFFFFF);
  static const Color textPrimaryLight   = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color primaryLight       = Color(0xFF1565C0);
  static const Color accent             = Color(0xFF2FD9F4);

  // — Legacy Dark Theme ————————————————————————————
  static const Color darkSurface       = Color(0xFF1E1E1E);
  static const Color darkBackground    = Color(0xFF121212);
  static const Color darkCard          = Color(0xFF2C2C2C);
  static const Color textPrimaryDark   = Color(0xFFE0E0E0);
  static const Color textSecondaryDark = Color(0xFF9E9E9E);
}
