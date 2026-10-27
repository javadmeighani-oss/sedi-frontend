import 'package:flutter/material.dart';

import '../../../../core/theme/sedi_palette.dart';

/// A3 Sedi-presence visual tokens only. Not the destination design system.
///
/// Hologram redesign (D-071/D-072): the orb is ~30 % smaller than the first
/// concept (210 dp at 390 dp width) and sits in the background layer.
class SediPresenceTokens {
  SediPresenceTokens._();

  /// Deep olive — resonance hairlines (readable on Soft Sage).
  static const Color presenceGreen = SediPalette.pistachio900;

  /// Sphere diameter / usable width. The four rings reach 2.0 radii on each
  /// side, so the whole hologram spans about 0.88 of the width (D-091).
  static const double orbWidthFactor = 0.44;
  static const double orbMinDiameter = 150;
  static const double orbMaxDiameter = 250;

  static const double visualizerHeight = 52;
  static const double barPitch = 4;
  static const int barCountMin = 96;
  static const int barCountMax = 100;

  /// ~20% reduction from the previous visual-amplitude maximum.
  static const double amplitudeScale = 0.80;

  /// Visibility-only scale on computed bar opacity. Not amplitude or energy.
  static const double barOpacityScale = 1.20;

  static double orbDiameterFor(double availableWidth) {
    return (availableWidth * orbWidthFactor)
        .clamp(orbMinDiameter, orbMaxDiameter)
        .toDouble();
  }

  static int barCountFor(double availableWidth) {
    return (availableWidth / barPitch)
        .round()
        .clamp(barCountMin, barCountMax)
        .toInt();
  }
}
