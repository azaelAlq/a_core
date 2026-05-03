import 'package:flutter/material.dart';

abstract class AppTextStyles {
  static const _font = 'YourFont'; // ← cambia por tu fuente

  static final textTheme = TextTheme(
    displayLarge: _s(57, FontWeight.w400, letterSpacing: -0.25),
    headlineLarge: _s(32, FontWeight.w500),
    headlineMedium: _s(28, FontWeight.w500),
    headlineSmall: _s(24, FontWeight.w500),
    titleLarge: _s(22, FontWeight.w500),
    titleMedium: _s(16, FontWeight.w500, letterSpacing: 0.15),
    titleSmall: _s(14, FontWeight.w500, letterSpacing: 0.1),
    bodyLarge: _s(16, FontWeight.w400),
    bodyMedium: _s(14, FontWeight.w400),
    bodySmall: _s(12, FontWeight.w400),
    labelLarge: _s(14, FontWeight.w500, letterSpacing: 0.1),
    labelMedium: _s(12, FontWeight.w500, letterSpacing: 0.5),
    labelSmall: _s(11, FontWeight.w500, letterSpacing: 0.5),
  );

  // Shortcuts usados en AppTheme
  static final labelLarge = _s(14, FontWeight.w500, letterSpacing: 0.1);
  static final labelMedium = _s(12, FontWeight.w500, letterSpacing: 0.5);
  static final labelSmall = _s(11, FontWeight.w500, letterSpacing: 0.5);
  static final bodyLarge = _s(16, FontWeight.w400);
  static final bodyMedium = _s(14, FontWeight.w400);
  static final bodySmall = _s(12, FontWeight.w400);
  static final titleLarge = _s(22, FontWeight.w500);

  static TextStyle _s(double size, FontWeight weight, {double? letterSpacing}) => TextStyle(
    fontFamily: _font,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
  );
}
