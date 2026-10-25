import 'package:flutter/material.dart';

/// Sedi Brand Palette v1 (approved) — the single colour source for the
/// hologram redesign (P0).
///
/// Surfaces: Charcoal + Shell about 65 %, Pistachio about 23 %.
/// Rose/Plum ("Skin" accent): about [roseShareDark] on dark pages and about
/// [roseShareLight] on light pages (D-074, Javad 2026-10-25).
///
/// Presentation only: no logic, no widgets.
class SediPalette {
  SediPalette._();

  // Pistachio — brand colour.
  static const Color pistachio900 = Color(0xFF48551F);
  static const Color pistachio700 = Color(0xFF869531);
  static const Color pistachio500 = Color(0xFFB8CB55);
  static const Color pistachio300 = Color(0xFFD5E383);
  static const Color pistachio100 = Color(0xFFEEF3D2);

  // Shell — warm human surfaces.
  static const Color shell500 = Color(0xFFD4CE93);
  static const Color shell300 = Color(0xFFF2E8CC);
  static const Color shell100 = Color(0xFFFBF8EE);

  // Rose / Plum ("Skin") accent.
  static const Color skin700 = Color(0xFF9F3E55);
  static const Color skin500 = Color(0xFFD85C73);
  static const Color skin300 = Color(0xFFF0A5B2);
  static const Color skin100 = Color(0xFFFFD1D9);

  // Charcoal — depth.
  static const Color charcoal950 = Color(0xFF161814);
  static const Color charcoal900 = Color(0xFF20231E);
  static const Color charcoal700 = Color(0xFF44483F);
  static const Color charcoal500 = Color(0xFF73786D);

  static const Color earth800 = Color(0xFF493C2D);

  /// Solid base under the translucent hologram dome (pistachio 900 / charcoal mix).
  static const Color domeUnderlay = Color(0xFF323B1C);

  /// Rose share of the surface on dark pages (about 12 %).
  static const double roseShareDark = 0.12;

  /// Rose share of the surface on light pages (about 3 %).
  static const double roseShareLight = 0.03;
}
