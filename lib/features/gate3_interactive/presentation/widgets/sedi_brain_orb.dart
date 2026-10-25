import 'package:flutter/material.dart';

import '../../models/gate3_interaction_state.dart';
import 'sedi_hologram_orb.dart';
import 'sedi_presence_tokens.dart';

/// Sedi presence = the approved hologram holding the official Sedi wordmark.
///
/// The wordmark is language-invariant (Latin) — see `sediOrbBrandLatin` in
/// `core/utils/brand_name.dart`. [lang] is kept for API stability.
class SediBrainOrb extends StatelessWidget {
  final Gate3InteractionState state;
  final String lang;
  final double? diameter;

  static const double widthFactor = SediPresenceTokens.orbWidthFactor;
  static const double minDiameter = SediPresenceTokens.orbMinDiameter;
  static const double maxDiameter = SediPresenceTokens.orbMaxDiameter;

  static double diameterFor(double availableWidth) =>
      SediPresenceTokens.orbDiameterFor(availableWidth);

  const SediBrainOrb({
    super.key,
    required this.state,
    required this.lang,
    this.diameter,
  });

  @override
  Widget build(BuildContext context) {
    final d = diameter ?? SediPresenceTokens.orbMinDiameter;
    return SediHologramOrb(state: state, diameter: d);
  }
}
