import 'package:flutter/material.dart';

import '../../models/gate3_interaction_state.dart';
import 'sedi_hologram_orb.dart';

/// Compact hologram at the top of the A3 destination pages (Profile, Memory,
/// Lifestyle, Gadgets) — minimal, centred, one static frame (no Ticker).
/// Presentation only.
class A3HologramHeader extends StatelessWidget {
  final double diameter;

  const A3HologramHeader({super.key, this.diameter = 76});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 18),
      child: Center(
        child: SediHologramOrb(
          state: Gate3InteractionState.idle,
          diameter: diameter,
          showRings: false,
          animate: false,
        ),
      ),
    );
  }
}
