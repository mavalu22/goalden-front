import 'package:flutter/material.dart';

abstract class AppColors {
  // Base
  static const background = Color(0xFF141414);
  static const surface = Color(0xFF1E1E1E);
  static const surfaceElevated = Color(0xFF252525);

  // Accent — the golden signature
  static const golden = Color(0xFFD4AF37);
  static const goldenDim = Color(0x33D4AF37);
  static const goldenBorder = Color(0x66D4AF37);

  // Text
  static const textPrimary = Color(0xFFE8E4DC);
  static const textSecondary = Color(0xFF9E9A93);
  static const textMuted = Color(0xFF5C5A56);

  // Semantic
  static const error = Color(0xFFE05C5C);
  static const success = golden;

  // Border
  static const border = Color(0xFF2A2A2A);
  static const borderSubtle = Color(0xFF1F1F1F);
}
