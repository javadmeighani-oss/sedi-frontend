import 'package:flutter/material.dart';

import '../../../../core/theme/sedi_palette.dart';

/// A3 / A2 scene background (LIGHT theme, D-080): Shell 100 with one soft
/// pistachio glow behind the hologram and a faint pistachio floor — like the
/// pistachio photograph: pistachio first, wine only as a tiny accent.
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
        const ColoredBox(color: SediPalette.shell100),
        _glow(
          const Alignment(0, -0.35),
          1.0,
          SediPalette.pistachio300.withOpacity(0.34),
        ),
        _glow(
          const Alignment(0, 1.15),
          0.9,
          SediPalette.pistachio100.withOpacity(0.9),
        ),
      ],
    );
  }
}
