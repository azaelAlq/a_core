import 'package:flutter/material.dart';

abstract class AppColors {
  // ── Primario (Azul) ────────────────────────────
  static const primary = Color(0xFF1565C0); // Azul base (Material Blue 800)
  static const primaryLight = Color(0xFF5E92F3); // Azul claro
  static const primaryContainer = Color(0xFFE3F2FD); // Fondo suave azulado
  static const onPrimary = Color(0xFFFFFFFF); // Texto sobre azul
  static const onPrimaryContainer = Color(0xFF0D47A1); // Azul oscuro para texto

  // ── Secundario (Azul verdoso elegante) ─────────
  static const secondary = Color(0xFF00838F); // Azul-teal
  static const onSecondary = Color(0xFFFFFFFF);

  // ── Semánticos ───────────────────────────────
  static const success = Color(0xFF0F6E56);
  static const successContainer = Color(0xFFE1F5EE);
  static const onSuccessContainer = Color(0xFF04342C);
  static const error = Color(0xFFA32D2D);
  static const errorContainer = Color(0xFFFCEBEB);
  static const onErrorContainer = Color(0xFF501313);
  static const warning = Color(0xFF854F0B);
  static const warningContainer = Color(0xFFFAEEDA);
  static const onWarningContainer = Color(0xFF412402);
  static const info = Color(0xFF185FA5);
  static const infoContainer = Color(0xFFE6F1FB);
  static const onInfoContainer = Color(0xFF042C53);

  // ── Tema Claro ───────────────────────────────
  static const lightBackground = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFF5F4F0);
  static const lightSurfaceVariant = Color(0xFFEDECEA);
  static const lightOutline = Color(0xFFE5E4E0);
  static const lightOutlineVariant = Color(0xFFD3D1C7);
  static const lightOnBackground = Color(0xFF1A1917);
  static const lightOnSurface = Color(0xFF1A1917);
  static const lightOnSurfaceMuted = Color(0xFF4A4945);
  static const lightOnSurfaceHint = Color(0xFF888780);

  // ── Tema Oscuro ───────────────────────────────
  static const darkBackground = Color(0xFF111110);
  static const darkSurface = Color(0xFF1E1E1C);
  static const darkSurfaceVariant = Color(0xFF2A2A28);
  static const darkOutline = Color(0xFF3A3A37);
  static const darkOutlineVariant = Color(0xFF5F5E5A);
  static const darkOnBackground = Color(0xFFF1EFE8);
  static const darkOnSurface = Color(0xFFF1EFE8);
  static const darkOnSurfaceMuted = Color(0xFFB4B2A9);
  static const darkOnSurfaceHint = Color(0xFF5F5E5A);
}
