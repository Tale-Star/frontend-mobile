import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Escala tipográfica oficial de Tale Star.
///
/// Combina Nunito (amigable y legible) para títulos infantiles y de lectura,
/// con Inter (preciso y neutro) para elementos de interfaz de padres y docentes.
abstract class AppTypography {
  // ---------------------------------------------------------------------------
  // Títulos — Nunito (Warm & Friendly)
  // ---------------------------------------------------------------------------
  static TextStyle displayLarge({Color? color}) => GoogleFonts.nunito(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.25,
        color: color,
      );

  static TextStyle displayMedium({Color? color}) => GoogleFonts.nunito(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: color,
      );

  static TextStyle titleLarge({Color? color}) => GoogleFonts.nunito(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: color,
      );

  static TextStyle titleMedium({Color? color}) => GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: color,
      );

  static TextStyle titleSmall({Color? color}) => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: color,
      );

  // ---------------------------------------------------------------------------
  // Cuerpo y UI — Inter (Claro y Accesible)
  // ---------------------------------------------------------------------------
  static TextStyle bodyLarge({Color? color}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color,
      );

  static TextStyle bodyMedium({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color,
      );

  static TextStyle bodySmall({Color? color}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: color,
      );

  // ---------------------------------------------------------------------------
  // Botones, Etiquetas y Formularios
  // ---------------------------------------------------------------------------
  static TextStyle button({Color? color}) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: color,
      );

  static TextStyle label({Color? color}) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: color,
      );

  static TextStyle caption({Color? color}) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: color,
      );
}
