import 'package:flutter/material.dart';

import '../../models/gate3_interaction_state.dart';
import 'sedi_brain_orb.dart';
import 'sedi_horizontal_resonance_visualizer.dart';
import 'sedi_presence_tokens.dart';

/// Background presence: the hologram on top, the horizontal resonance bars
/// across the middle of the screen below it. The chat floats (transparent)
/// over this layer.
class SediOrbPresence extends StatefulWidget {
  final Gate3InteractionState state;
  final String lang;

  /// Hologram brightness: 1.0 empty/first open, ~0.5 active chat, ~0.3 long
  /// history. Bars follow (dimmed when the hologram is dim).
  final double ambient;

  /// Vertical gap between the hologram and the resonance bars.
  final double gap;

  /// Horizontal inset from the A3 usable edge (responsive, not device-fixed).
  static const double horizontalInset = 12;

  /// Responsive gap: about 13 % of the available height, clamped.
  static double gapFor(double availableHeight) =>
      (availableHeight * 0.13).clamp(56.0, 120.0).toDouble();

  /// Total presence height for a usable width and gap.
  static double heightFor(double usableWidth, double gap) =>
      SediBrainOrb.diameterFor(usableWidth) +
      gap +
      SediPresenceTokens.visualizerHeight;

  const SediOrbPresence({
    super.key,
    required this.state,
    required this.lang,
    this.ambient = 1.0,
    this.gap = 72,
  });

  @override
  State<SediOrbPresence> createState() => _SediOrbPresenceState();
}

class _SediOrbPresenceState extends State<SediOrbPresence>
    with SingleTickerProviderStateMixin {
  late final AnimationController _phase;

  @override
  void initState() {
    super.initState();
    _phase = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final usable =
            maxW.clamp(SediPresenceTokens.orbMinDiameter, maxW).toDouble();
        final orbD = SediBrainOrb.diameterFor(usable);
        final bars = SediPresenceTokens.barCountFor(usable);
        final height = SediOrbPresence.heightFor(usable, widget.gap);
        final barsOpacity = widget.ambient < 0.4 ? 0.35 : 1.0;

        return SizedBox(
          width: usable,
          height: height,
          child: Column(
            children: [
              SizedBox(
                height: orbD,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: widget.ambient.clamp(0.0, 1.0).toDouble(),
                    duration: const Duration(milliseconds: 400),
                    child: SediBrainOrb(
                      state: widget.state,
                      lang: widget.lang,
                      diameter: orbD,
                    ),
                  ),
                ),
              ),
              SizedBox(height: widget.gap),
              AnimatedOpacity(
                opacity: barsOpacity,
                duration: const Duration(milliseconds: 400),
                child: SediHorizontalResonanceVisualizer(
                  state: widget.state,
                  phaseListenable: _phase,
                  segmentBarCount: bars,
                  globalBarOffset: 0,
                  globalBarTotal: bars,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
