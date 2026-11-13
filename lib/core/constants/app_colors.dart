import 'package:flutter/material.dart';
abstract final class AppColors {
  // Background and surfaces.
  static const Color background = Color(0xFF0D0221);
  static const Color surface = Color(0xFF0F084B);
  static const Color surfaceLight = Color(0xFF26408B);

  // Accent.
  static const Color accent = Color(0xFFA6CFD5);
  static const Color accentLight = Color(0xFFC2E7D9);

  // Text.
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA6CFD5);
  static const Color textMuted = Color(0xFF6B7280);

  // Site status.
  static const Color recommended = Color(0xFF4CAF50);
  static const Color acceptable = Color(0xFFFFC107);
  static const Color notRecommended = Color(0xFFFF5252);

  // Warning levels.
  static const Color warningNone = Color(0xFF4CAF50);
  static const Color warningCaution = Color(0xFFFFC107);
  static const Color warningHigh = Color(0xFFFF5252);
}
