import 'package:flutter/material.dart';

/// Central color palette for the attendance app.
/// Tuned to match the purple gradient + soft-lavender UI shown in the
/// design reference (header gradient, status chips, cards).
class AppColors {
  AppColors._();

  // Core brand purples (used for the header gradient, buttons, highlights)
  static const Color primaryPurple = Color(0xFF7C3AED);
  static const Color deepPurple = Color(0xFF4C1D95);

  // Soft backgrounds
  static const Color pageBg = Color(0xFFF8F7FC);
  static const Color softPurple = Color(0xFFF1EBFF); // "Class 8-A" pill bg
  static const Color lavender = Color(0xFFEDE6FB); // avatar circle bg

  // Text
  static const Color darkText = Color(0xFF1F2937);
  static const Color mutedText = Color(0xFF6B7280);

  // Status colors
  static const Color green = Color(0xFF22C55E); // Present
  static const Color amber = Color(0xFFF59E0B); // Late
  static const Color red = Color(0xFFEF4444); // Absent

  static const Color white = Color(0xFFFFFFFF);
}