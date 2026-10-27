import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/sedi_palette.dart';
import '../../models/gate3_interaction_state.dart';
import 'sedi_hologram_orb.dart';

/// Sedi's "Living Echo" presence (D-127, approved by Javad on the 2026-10-27 concept).
///
/// - Empty chat: a large, fully visible glass sphere (the official Sedi wordmark ONLY) that breathes, with echo
///   ripples travelling outward - «صدی» means echo.
/// - Once the conversation has started the sphere moves up into a compact header, so no text is ever read over it.
/// - States: idle breathes slowly; listening swells with fast ripples; thinking pulses; speaking ripples steadily.
///
/// Presentation only. State authority is [Gate3InteractionState]. Reduced motion (and `flutter test`) freezes the
/// ripples. No microphone, I9 or health data.
class SediLivingEcho extends StatefulWidget {
  final Gate3InteractionState state;

  /// false = hero (empty chat); true = compact header (conversation running / keyboard open).
  final bool compact;

  /// Edge of the square hero canvas (ripples included); chosen by the page from the available height.
  final double heroSize;

  /// Space reserved above for the destinations tray.
  static const double topInset = 44;
  static const double compactCanvas = 96;
  static const double compactSphere = 60;
  static const double heroSphereFactor = 0.56;

  const SediLivingEcho({
    super.key,
    required this.state,
    required this.compact,
    required this.heroSize,
  });

  /// Total height the widget takes for the given mode (used by tests and layout maths).
  static double heightFor({required bool compact, required double heroSize}) =>
      topInset + (compact ? compactCanvas : heroSize);

  @override
  State<SediLivingEcho> createState() => _SediLivingEchoState();
}

class _SediLivingEchoState extends State<SediLivingEcho>
    with SingleTickerProviderStateMixin {
  static const double _loopSeconds = 3600;
  AnimationController? _clock;

  /// Frozen under `flutter test` (an endless animation would keep `pumpAndSettle` from settling).
  static bool get _animated => Platform.environment['FLUTTER_TEST'] != 'true';

  @override
  void initState() {
    super.initState();
    if (_animated) {
      _clock = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 3600),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _clock?.dispose();
    super.dispose();
  }

  /// (rings, seconds per ripple cycle, strength 0..1) per state.
  static (int, double, double) _ripple(Gate3InteractionState s) {
    switch (s) {
      case Gate3InteractionState.idle:
        return (3, 5.4, 0.5);
      case Gate3InteractionState.listening:
        return (4, 3.2, 0.7);
      case Gate3InteractionState.thinking:
        return (2, 4.2, 0.45);
      case Gate3InteractionState.speaking:
        return (3, 3.6, 0.6);
    }
  }

  static double _swell(Gate3InteractionState s) {
    switch (s) {
      case Gate3InteractionState.listening:
        return 1.05;
      case Gate3InteractionState.speaking:
        return 1.03;
      case Gate3InteractionState.thinking:
        return 1.02;
      case Gate3InteractionState.idle:
        return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: widget.compact ? 1 : 0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
      builder: (context, t, _) {
        final canvas = _lerp(
          widget.heroSize,
          SediLivingEcho.compactCanvas,
          t,
        );
        final sphere = _lerp(
          widget.heroSize * SediLivingEcho.heroSphereFactor,
          SediLivingEcho.compactSphere,
          t,
        );
        return SizedBox(
          height: SediLivingEcho.topInset + canvas,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.only(top: SediLivingEcho.topInset),
            child: Center(
              child: SizedBox(
                width: canvas,
                height: canvas,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    if (!reduce && _clock != null)
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _clock!,
                          builder: (context, _) {
                            final (rings, cycle, strength) = _ripple(
                              widget.state,
                            );
                            return CustomPaint(
                              painter: _EchoRipplePainter(
                                seconds: _clock!.value * _loopSeconds,
                                sphereDiameter: sphere,
                                rings: rings,
                                cycleSeconds: cycle,
                                strength: strength,
                              ),
                            );
                          },
                        ),
                      ),
                    AnimatedScale(
                      scale: _swell(widget.state),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                      child: SediHologramOrb(
                        state: widget.state,
                        diameter: sphere,
                        showRings: false,
                        animate: _animated && !reduce,
                        keyedLogo: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}

/// Echo rings: each ring starts at the sphere's edge, grows and fades like a sound travelling through the room.
class _EchoRipplePainter extends CustomPainter {
  final double seconds;
  final double sphereDiameter;
  final int rings;
  final double cycleSeconds;
  final double strength;

  const _EchoRipplePainter({
    required this.seconds,
    required this.sphereDiameter,
    required this.rings,
    required this.cycleSeconds,
    required this.strength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final base = sphereDiameter / 2;
    for (var k = 0; k < rings; k++) {
      final phase = ((seconds / cycleSeconds) + k / rings) % 1.0;
      final radius = base * (0.62 + 1.28 * phase);
      final alpha = (1 - phase) * strength;
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, base * 0.016)
          ..isAntiAlias = true
          ..color = SediPalette.pistachio900.withOpacity(alpha.clamp(0.0, 1.0)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EchoRipplePainter old) =>
      old.seconds != seconds ||
      old.sphereDiameter != sphereDiameter ||
      old.rings != rings ||
      old.cycleSeconds != cycleSeconds ||
      old.strength != strength;
}
