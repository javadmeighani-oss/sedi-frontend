import 'package:flutter/material.dart';

import '../../../../core/theme/sedi_glass.dart';

/// A3 / A2 scene background. Pilot V1 (R-034, REVISES D-085 "flat sage, no gradients"): a soft pistachio vertical
/// gradient with two faint pistachio lights, so the glass layers above it have something to blur and lift off.
/// Still calm and eye-comfortable. Presentation only.
class SediSceneBackdrop extends StatelessWidget {
  const SediSceneBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: SediGlass.pageGradient,
          stops: SediGlass.pageStops,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: const [
          Positioned(
            left: -60,
            top: 330,
            child: _Light(size: 240, color: Color(0x8CB5CF5E)),
          ),
          Positioned(
            right: -80,
            top: 560,
            child: _Light(size: 260, color: Color(0x618FAE3E)),
          ),
        ],
      ),
    );
  }
}

class _Light extends StatelessWidget {
  final double size;
  final Color color;

  const _Light({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withOpacity(0)],
            stops: const [0.0, 0.7],
          ),
        ),
      ),
    );
  }
}
