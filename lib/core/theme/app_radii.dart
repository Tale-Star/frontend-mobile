import 'package:flutter/material.dart';

/// Radios de borde oficiales de Tale Star (§4 del Implementation Plan).
abstract class AppRadii {
  static const double smValue = 10.0;
  static const double mdValue = 16.0;
  static const double lgValue = 22.0;
  static const double pillValue = 999.0;

  static const BorderRadius sm = BorderRadius.all(Radius.circular(smValue));
  static const BorderRadius md = BorderRadius.all(Radius.circular(mdValue));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(lgValue));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(pillValue));
}
