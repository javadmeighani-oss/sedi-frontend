import 'package:flutter/material.dart';

import '../../../../core/theme/sedi_glass.dart';
import '../../../../core/theme/sedi_palette.dart';

/// Compact circular action control for the Gate 3 composer.
///
/// Pilot V1 (R-034): three looks - [bare] is only a thin icon with no fill or border (attach), [sphere] is the round
/// pistachio 3D glass control (mic / send), and the default is the glass circle; a solid [backgroundColor] (the
/// recording stop button) overrides the fill.
class Gate3ComposerActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? glowColor;
  final double size;
  final double iconSize;

  /// No fill, no border, no shadow: just the icon.
  final bool bare;

  /// Round pistachio 3D glass control.
  final bool sphere;

  const Gate3ComposerActionButton({
    super.key,
    required this.icon,
    this.onTap,
    this.iconColor,
    this.backgroundColor,
    this.glowColor,
    this.size = 36,
    this.iconSize = 22,
    this.bare = false,
    this.sphere = false,
  });

  BoxDecoration? _decoration(bool enabled) {
    if (bare) return null;
    if (backgroundColor != null) {
      return BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        boxShadow: glowColor == null
            ? null
            : [
                BoxShadow(
                  color: glowColor!.withOpacity(0.45),
                  blurRadius: 20,
                ),
              ],
      );
    }
    if (sphere) return SediGlass.pistachioSphere();
    return BoxDecoration(
      shape: BoxShape.circle,
      color: SediPalette.sageFill.withOpacity(enabled ? 1.0 : 0.5),
      border: Border.all(color: SediPalette.sageLine),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final defaultIconColor = bare
        ? SediGlass.ink
        : sphere
            ? SediGlass.inkDeep
            : SediPalette.charcoal950;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: _decoration(enabled),
          child: Icon(
            icon,
            size: iconSize,
            color: iconColor ??
                (enabled
                    ? defaultIconColor
                    : SediPalette.charcoal500.withOpacity(0.5)),
          ),
        ),
      ),
    );
  }
}
