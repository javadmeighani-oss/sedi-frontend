import 'package:flutter/material.dart';

import '../../../../core/theme/sedi_glass.dart';

/// One destination in the A3 tray. Pilot V1 (R-034): a frosted glass tile with a thin-line deep-olive icon and a
/// short label. [plainIcon] is kept for API stability (all tiles share the same look).
class Gate3MainIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? badge;
  final bool plainIcon;

  static const double tileSize = 58;
  static const double iconSize = 29;

  const Gate3MainIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.plainIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      containedInkWell: true,
      highlightShape: BoxShape.rectangle,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: tileSize,
                  height: tileSize,
                  decoration: SediGlass.tile(),
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: SediGlass.ink,
                  ),
                ),
                if (badge != null)
                  PositionedDirectional(
                    top: -4,
                    end: -4,
                    child: badge!,
                  ),
              ],
            ),
            const SizedBox(height: 7),
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: SediGlass.ink,
                    height: 1.15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
