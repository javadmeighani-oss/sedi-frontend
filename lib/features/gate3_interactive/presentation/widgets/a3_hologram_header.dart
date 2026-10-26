import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import '../../models/gate3_interaction_state.dart';
import 'sedi_hologram_orb.dart';

/// Compact hologram at the top of the A3 destination pages (Profile, Memory,
/// Lifestyle, Gadgets) — minimal, centred, with the slow idle motion of the
/// planets (D-097). Under `flutter test` it renders one static frame so
/// `pumpAndSettle` can settle. Presentation only.
class A3HologramHeader extends StatelessWidget {
  final double diameter;
  final bool _inAppBar;

  const A3HologramHeader({super.key, this.diameter = 76}) : _inAppBar = false;

  /// Animated on a real device; frozen under `flutter test` (an endless
  /// animation would keep `pumpAndSettle` from settling).
  static bool get _animate => Platform.environment['FLUTTER_TEST'] != 'true';

  /// Small hologram for an AppBar action (pages whose list must keep its height).
  const A3HologramHeader.appBarAction({super.key})
    : diameter = 34,
      _inAppBar = true;

  @override
  Widget build(BuildContext context) {
    if (_inAppBar) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(end: 16, start: 16),
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
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 18),
      child: Center(
        // Same sphere size as before; the four rings spread sideways only, so
        // the header keeps its height (D-096); the planets move slowly (D-097).
        child: SediHologramOrb(
          state: Gate3InteractionState.idle,
          diameter: diameter,
          animate: _animate,
        ),
      ),
    );
  }
}
