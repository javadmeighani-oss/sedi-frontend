import 'package:flutter/material.dart';

import '../../../../core/theme/sedi_palette.dart';

/// A3 / A2 scene background: ONE flat Soft Sage colour (D-085, option F) - no
/// glows, no gradients: calm and eye-comfortable (not white, not dark).
/// Presentation only.
class SediSceneBackdrop extends StatelessWidget {
  const SediSceneBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: SediPalette.sagePage);
  }
}
