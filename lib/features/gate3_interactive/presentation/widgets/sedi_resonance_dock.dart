import 'package:flutter/widgets.dart';

import '../../models/gate3_interaction_state.dart';
import 'sedi_horizontal_resonance_visualizer.dart';
import 'sedi_presence_tokens.dart';

/// Sedi's resonance, docked just above the composer (D-102, Javad's phone test): centred, about half the screen
/// width, never over the chat text. Same four states and motions as before; state authority = [Gate3InteractionState].
class SediResonanceDock extends StatelessWidget {
  final Gate3InteractionState state;

  /// Fraction of the available width (about half of the former full-width line).
  static const double widthFactor = 0.5;

  /// A little shorter than the old centre line so the chat keeps its room.
  static const double height = 44;

  const SediResonanceDock({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 6),
        child: SizedBox(
          height: height,
          child: Center(
            child: FractionallySizedBox(
              widthFactor: widthFactor,
              child: SediHorizontalResonanceVisualizer(
                state: state,
                heightOverride: height,
                segmentBarCount: SediPresenceTokens.barCountMin ~/ 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
