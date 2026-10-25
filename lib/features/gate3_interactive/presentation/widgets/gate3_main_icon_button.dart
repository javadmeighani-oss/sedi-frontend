import 'package:flutter/material.dart';

import '../../../../core/theme/sedi_palette.dart';

/// One destination in the A3 tray. Hologram redesign: glass tile, shell icon,
/// soft rose edge. [plainIcon] is kept for API stability (all tiles share the
/// same glass look now).
class Gate3MainIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? badge;
  final bool plainIcon;

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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.78),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: SediPalette.pistachio700.withOpacity(0.22),
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: SediPalette.charcoal950,
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
            const SizedBox(height: 6),
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
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: SediPalette.charcoal700,
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
