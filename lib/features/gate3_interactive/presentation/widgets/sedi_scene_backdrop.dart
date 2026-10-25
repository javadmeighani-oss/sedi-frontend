import 'package:flutter/material.dart';

import '../../../../core/theme/sedi_palette.dart';

/// A3 scene background: Charcoal 950 with one soft pistachio glow behind the
/// hologram (minimal — rose is reserved for tiny functional accents, D-078).
/// Presentation only.
class SediSceneBackdrop extends StatelessWidget {
  const SediSceneBackdrop({super.key});

  Widget _glow(Alignment center, double radius, Color color) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: center,
              radius: radius,
              colors: [color, color.withOpacity(0.0)],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: SediPalette.charcoal950),
        _glow(
          const Alignment(0, -0.45),
          0.95,
          SediPalette.pistachio500.withOpacity(0.20),
        ),
      ],
    );
  }
}
