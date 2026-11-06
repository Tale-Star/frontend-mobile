import 'package:flutter/material.dart';

/// Tokens oficiales de color de Tale Star (§6.1.1 del README y tokens.css).
abstract class AppColors {
  // ---------------------------------------------------------------------------
  // Marca Tale Star (Púrpura Creativo)
  // ---------------------------------------------------------------------------
  static const Color primary900 = Color(0xFF5B3DFA); // Botones primarios y acento
  static const Color primary700 = Color(0xFF7454FD); // Hover / Acento secundario
  static const Color primary500 = Color(0xFF9974FE);
  static const Color primary300 = Color(0xFFB194FE);
  static const Color primary100 = Color(0xFFE6DBFE);

  // ---------------------------------------------------------------------------
  // Superficies y Fondos — Modo Claro
  // ---------------------------------------------------------------------------
  static const Color bgLight = Color(0xFFF5F6F8);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surface2Light = Color(0xFFF0F1F4);
  static const Color surface3Light = Color(0xFFE9EBEF);

  // ---------------------------------------------------------------------------
  // Textos — Modo Claro
  // ---------------------------------------------------------------------------
  static const Color textPrimaryLight = Color(0xFF15151B);
  static const Color textSecondaryLight = Color(0xFF5D606D);
  static const Color textTertiaryLight = Color(0xFF8D909B);

  // ---------------------------------------------------------------------------
  // Superficies y Fondos — Modo Oscuro
  // ---------------------------------------------------------------------------
  static const Color bgDark = Color(0xFF0F0F14);
  static const Color surfaceDark = Color(0xFF181820);
  static const Color surface2Dark = Color(0xFF22222D);
  static const Color surface3Dark = Color(0xFF2D2D3B);

  // ---------------------------------------------------------------------------
  // Textos — Modo Oscuro
  // ---------------------------------------------------------------------------
  static const Color textPrimaryDark = Color(0xFFF3F4F6);
  static const Color textSecondaryDark = Color(0xFFA1A4B0);
  static const Color textTertiaryDark = Color(0xFF6C6F7E);

  // ---------------------------------------------------------------------------
  // Semántica y Estados
  // ---------------------------------------------------------------------------
  static const Color success = Color(0xFF22A06B);
  static const Color warning = Color(0xFFE99A22);
  static const Color danger = Color(0xFFE05265);
  static const Color info = Color(0xFF2D7FF9);

  // ---------------------------------------------------------------------------
  // Modo Niño (Modo de concentración cálido y protegido)
  // ---------------------------------------------------------------------------
  static const Color childModeAccent = Color(0xFFFF9E2C);
  static const Color childModeBg = Color(0xFFFFF9F0);
  static const Color childModeCard = Color(0xFFFFFFFF);
}
