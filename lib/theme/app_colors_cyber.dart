import 'package:flutter/material.dart';

/// Cyber-Modern IT Support — Stitch Design System
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary        = Color(0xFFBEC6E0);
  static const Color onPrimary      = Color(0xFF283044);
  static const Color primaryContainer = Color(0xFF0F172A);

  static const Color secondary      = Color(0xFFADC6FF);
  static const Color secondaryContainer = Color(0xFF0566D9);

  static const Color tertiary       = Color(0xFF2FD9F4); // Cyan accent
  static const Color tertiaryDim    = Color(0xFF2FD9F4);
  static const Color tertiaryContainer = Color(0xFF001B20);
  static const Color onTertiaryContainer = Color(0xFF008EA1);

  // ── Surfaces ───────────────────────────────────────────────────────────────
  static const Color background     = Color(0xFF0F172A); // deep navy
  static const Color surface        = Color(0xFF101415);
  static const Color surfaceContainerLowest = Color(0xFF0B0F10);
  static const Color surfaceContainerLow    = Color(0xFF191C1E);
  static const Color surfaceContainer       = Color(0xFF1D2022);
  static const Color surfaceContainerHigh   = Color(0xFF272A2C);
  static const Color surfaceContainerHighest = Color(0xFF323537);
  static const Color surfaceBright   = Color(0xFF363A3B);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color onSurface      = Color(0xFFE0E3E5);
  static const Color onSurfaceVariant = Color(0xFFC6C6CD);
  static const Color outline        = Color(0xFF909097);
  static const Color outlineVariant  = Color(0xFF45464D);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color error          = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color success        = Color(0xFF2FD9F4); // use cyan for resolved
  static const Color warning        = Color(0xFFFFB74D);

  // ── Priority ───────────────────────────────────────────────────────────────
  static const Color priorityUrgent = Color(0xFFFF5449);
  static const Color priorityHigh   = Color(0xFFFFB74D);
  static const Color priorityMedium = Color(0xFFADC6FF);
  static const Color priorityLow    = Color(0xFF909097);

  // ── Glass ──────────────────────────────────────────────────────────────────
  static Color glassCard   = const Color(0xFF1D2022).withValues(alpha: 0.7);
  static Color glassBorder = Colors.white.withValues(alpha: 0.1);
  static Color cyanGlow    = const Color(0xFF2FD9F4).withValues(alpha: 0.15);
}


