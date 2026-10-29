import 'package:flutter/material.dart';

import '../../../../core/theme/sedi_glass.dart';

/// Presentation-only collapsible tray around the A3 destination icon row.
///
/// Pilot V1 (R-034): collapsed it is only a small glass pill with a thin chevron; open it is one frosted glass
/// panel dropping from the top, with the pill hanging on its lower edge and its chevron pointing up. Same API.
class Gate3TopNavigationTray extends StatefulWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;
  final String expandLabel;
  final String collapseLabel;

  static const Duration toggleDuration = Duration(milliseconds: 240);
  static const Curve toggleCurve = Curves.easeOutCubic;

  /// Tap target of the pill (the visible pill is [pillHeight] tall inside it).
  static const double handleHeight = 44;
  static const double pillWidth = 78;
  static const double pillHeight = 32;

  /// Extra height the open panel needs below the collapsed tray (the page moves its content down by this much).
  static const double expandedExtraHeight = 88;

  const Gate3TopNavigationTray({
    super.key,
    required this.expanded,
    required this.onToggle,
    required this.child,
    required this.expandLabel,
    required this.collapseLabel,
  });

  @override
  State<Gate3TopNavigationTray> createState() => _Gate3TopNavigationTrayState();
}

class _Gate3TopNavigationTrayState extends State<Gate3TopNavigationTray>
    with SingleTickerProviderStateMixin {
  late final AnimationController _size;

  // The pill's tap box sits 2dp from the top when collapsed (its visible pill 8dp from the top); when open the pill
  // hangs 16dp over the panel's lower edge, so the box bottom is 22dp below that edge.
  static const double _gapCollapsed = 2 + Gate3TopNavigationTray.handleHeight;
  static const double _gapExpanded = 22;

  @override
  void initState() {
    super.initState();
    _size =
        AnimationController(
          vsync: this,
          duration: Gate3TopNavigationTray.toggleDuration,
          value: widget.expanded ? 1 : 0,
        )..addListener(() {
          if (mounted) setState(() {});
        });
  }

  @override
  void didUpdateWidget(covariant Gate3TopNavigationTray oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded != widget.expanded) {
      _size.animateTo(
        widget.expanded ? 1 : 0,
        curve: Gate3TopNavigationTray.toggleCurve,
      );
    }
  }

  @override
  void dispose() {
    _size.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _size.value;
    final showPanel = widget.expanded || t > 0.001;
    const radius = BorderRadius.vertical(bottom: Radius.circular(34));
    final gap = _gapCollapsed + (_gapExpanded - _gapCollapsed) * t;

    final Widget panel = showPanel
        ? SediGlass.blur(
            radius: radius,
            sigma: 22,
            child: DecoratedBox(
              decoration: SediGlass.trayPanel(radius),
              child: ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: t,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 14, 10, 22),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          )
        : const SizedBox(width: double.infinity, height: 0);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: gap),
          child: panel,
        ),
        Positioned(
          bottom: 0,
          child: Semantics(
            key: const ValueKey('a3-top-tray-semantics'),
            button: true,
            label: widget.expanded ? widget.collapseLabel : widget.expandLabel,
            child: Material(
              color: const Color(0x00000000),
              child: InkWell(
                key: const ValueKey('a3-top-tray-toggle'),
                onTap: widget.onToggle,
                customBorder: const StadiumBorder(),
                child: SizedBox(
                  width: Gate3TopNavigationTray.pillWidth,
                  height: Gate3TopNavigationTray.handleHeight,
                  child: Center(
                    child: SizedBox(
                      width: Gate3TopNavigationTray.pillWidth,
                      height: Gate3TopNavigationTray.pillHeight,
                      child: DecoratedBox(
                        decoration: SediGlass.pill(strong: widget.expanded),
                        child: Center(
                          child: _TrayChevron(expanded: widget.expanded),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Visible chevron only: thin, rounded, deep olive. The tap target is the pill's box.
class _TrayChevron extends StatelessWidget {
  static const double visualSize = 18 * 1.56;
  static const double strokeWidth = 1.9;

  final bool expanded;

  const _TrayChevron({required this.expanded});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size.square(visualSize),
      painter: _TrayChevronPainter(
        pointingUp: expanded,
        color: SediGlass.ink,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _TrayChevronPainter extends CustomPainter {
  final bool pointingUp;
  final Color color;
  final double strokeWidth;

  const _TrayChevronPainter({
    required this.pointingUp,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final insetX = size.width * 0.22;
    final top = size.height * 0.35;
    final bottom = size.height * 0.62;
    final midX = size.width / 2;
    final apexY = pointingUp ? top : bottom;
    final wingY = pointingUp ? bottom : top;

    final path = Path()
      ..moveTo(insetX, wingY)
      ..lineTo(midX, apexY)
      ..lineTo(size.width - insetX, wingY);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrayChevronPainter oldDelegate) =>
      oldDelegate.pointingUp != pointingUp ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
