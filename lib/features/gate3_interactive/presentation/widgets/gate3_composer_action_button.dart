import 'package:flutter/material.dart';

import '../../../../core/theme/sedi_palette.dart';

/// Compact circular action control for the Gate 3 composer.
///
/// Hologram redesign: glass by default; primary actions pass a solid
/// [backgroundColor] (pistachio / rose) and an optional [glowColor].
class Gate3ComposerActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? glowColor;
  final double size;
  final double iconSize;

  const Gate3ComposerActionButton({
    super.key,
    required this.icon,
    this.onTap,
    this.iconColor,
    this.backgroundColor,
    this.glowColor,
    this.size = 36,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final solid = backgroundColor != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor ??
                SediPalette.shell100.withOpacity(enabled ? 0.09 : 0.05),
            border: solid
                ? null
                : Border.all(color: SediPalette.shell100.withOpacity(0.16)),
            boxShadow: glowColor == null
                ? null
                : [
                    BoxShadow(
                      color: glowColor!.withOpacity(0.45),
                      blurRadius: 20,
                    ),
                  ],
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: iconColor ??
                (enabled
                    ? SediPalette.shell100
                    : SediPalette.shell100.withOpacity(0.35)),
          ),
        ),
      ),
    );
  }
}
