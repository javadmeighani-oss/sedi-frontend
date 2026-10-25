import 'package:flutter/material.dart';

import '../../../../core/theme/sedi_palette.dart';

/// A3 scene background: Charcoal 950 with a pistachio glow behind the
/// hologram and a rose/plum glow in the corners (about 12 % rose on dark
/// pages — D-074). Presentation only.
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
        _glow(
          const Alignment(1, 1),
          1.0,
          SediPalette.skin500.withOpacity(0.21),
        ),
        _glow(
          const Alignment(-1, 0.25),
          0.8,
          SediPalette.skin700.withOpacity(0.16),
        ),
      ],
    );
  }
}
