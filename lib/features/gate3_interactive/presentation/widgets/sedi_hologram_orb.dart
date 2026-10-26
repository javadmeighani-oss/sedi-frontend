import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/theme/sedi_palette.dart';
import '../../models/gate3_interaction_state.dart';

/// Sedi hologram, LIGHT theme (D-080): a bright pistachio glass dome holding
/// ONLY the official Sedi wordmark (deep olive, always crisp and opaque),
/// wrapped by a soft pistachio halo and two orbit rings.
///
/// Presentation only. State authority is [Gate3InteractionState]
/// (idle / listening / thinking / speaking). No microphone, I9 or health data.
/// The wordmark is language-invariant (Latin "Sedi") on purpose.
///
/// [dim] fades the dome and halo only — never the wordmark.
/// Reduced motion (`MediaQuery.disableAnimations`) freezes every animation.
class SediHologramOrb extends StatefulWidget {
  final Gate3InteractionState state;
  final double diameter;
  final bool showLogo;

  /// Orbit rings are skipped for small icons (< [ringMinDiameter]).
  final bool showRings;

  /// false = one static frame (list avatars, icons): no Ticker is started.
  final bool animate;

  /// 0..1 brightness of the dome and halo (the wordmark always stays 100 %).
  final double dim;

  static const String logoAsset = 'assets/images/sedi_wordmark.png';
  static const double logoWidthFactor = 0.68;
  static const double logoAspect = 906 / 315;
  static const double ringMinDiameter = 60;
  static const ValueKey<String> logoKey = ValueKey<String>(
    'sedi-hologram-logo',
  );

  const SediHologramOrb({
    super.key,
    required this.state,
    required this.diameter,
    this.showLogo = true,
    this.showRings = true,
    this.animate = true,
    this.dim = 1.0,
  });

  @override
  State<SediHologramOrb> createState() => _SediHologramOrbState();
}

/// Shared animation clock: painters repaint from it without rebuilding widgets.
class _HoloClock extends ChangeNotifier {
  Gate3InteractionState state = Gate3InteractionState.idle;
  double holoTurns = 0;

  /// Seconds of planet travel (speed depends on the state).
  double orbitSec = 0;
  double breath = 0;
  double pulse = 0;
  double ripple = 0;

  static double _holoSpeed(Gate3InteractionState s) {
    switch (s) {
      case Gate3InteractionState.idle:
        return 1 / 16;
      case Gate3InteractionState.listening:
        return 1 / 12;
      case Gate3InteractionState.thinking:
        return 1 / 4;
      case Gate3InteractionState.speaking:
        return 1 / 10;
    }
  }

  /// Planet travel speed multiplier: calm when watching/listening, quick
  /// while thinking, steady while speaking.
  static double _orbitSpeed(Gate3InteractionState s) {
    switch (s) {
      case Gate3InteractionState.thinking:
        return 2.4;
      case Gate3InteractionState.speaking:
        return 1.4;
      case Gate3InteractionState.listening:
        return 0.7;
      case Gate3InteractionState.idle:
        return 1.0;
    }
  }

  /// Repaint once without advancing (state changed while motion is reduced).
  void poke() => notifyListeners();

  void advance(double dt) {
    holoTurns = (holoTurns + dt * _holoSpeed(state)) % 1.0;
    orbitSec =
        (orbitSec + dt * _orbitSpeed(state)) %
        11160.0; // lcm of the planet periods: no jump on wrap
    breath = (breath + dt * (2 * math.pi / 5.5)) % (2 * math.pi);
    pulse = (pulse + dt * (2 * math.pi / 1.1)) % (2 * math.pi);
    if (state == Gate3InteractionState.listening) {
      ripple = (ripple + dt / 2.6) % 1.0;
    } else {
      ripple = 0;
    }
    notifyListeners();
  }
}

class _SediHologramOrbState extends State<SediHologramOrb>
    with SingleTickerProviderStateMixin {
  final _HoloClock _clock = _HoloClock();
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _clock.state = widget.state;
    _ticker = createTicker(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion =
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ||
        !widget.animate;
    if (_reduceMotion) {
      if (_ticker.isActive) _ticker.stop();
    } else if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(covariant SediHologramOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _clock.state = widget.state;
      if (_reduceMotion) _clock.poke();
    }
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1000000.0;
    _last = elapsed;
    _clock.advance(dt.clamp(0.0, 0.1).toDouble());
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  /// Deep-olive wordmark: crisp, opaque, with a faint light halo to lift the edges.
  Widget _logo(double d) {
    final w = d * SediHologramOrb.logoWidthFactor;
    final h = w / SediHologramOrb.logoAspect;
    Widget image() => Image.asset(
      SediHologramOrb.logoAsset,
      width: w,
      height: h,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) =>
          SizedBox(width: w, height: h),
    );
    return Align(
      alignment: const Alignment(0, 0.04),
      child: SizedBox(
        width: w,
        height: h,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: d * 0.018,
                sigmaY: d * 0.018,
              ),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  SediPalette.shell100.withOpacity(0.75),
                  BlendMode.srcIn,
                ),
                child: image(),
              ),
            ),
            ColorFiltered(
              key: SediHologramOrb.logoKey,
              colorFilter: const ColorFilter.mode(
                SediPalette.pistachio900,
                BlendMode.srcIn,
              ),
              child: image(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.diameter;
    // Rings reach 2.0 sphere radii (= 2.0 d / 2 on each side) plus planet glow.
    final outer = d * 2.25;
    final rings = widget.showRings && d >= SediHologramOrb.ringMinDiameter;
    final dim = widget.dim.clamp(0.0, 1.0).toDouble();

    // Layer order (v4, D-091): back half of the rings -> glass sphere -> front
    // half of the rings -> wordmark. The ring front passes below the wordmark.
    Widget ringLayer({required bool front}) => Positioned(
      left: -(outer - d) / 2,
      top: -(outer - d) / 2,
      width: outer,
      height: outer,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: dim,
          duration: const Duration(milliseconds: 400),
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _AuraRingsPainter(
                clock: _clock,
                diameter: d,
                rings: rings,
                front: front,
              ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      label: 'Sedi',
      image: true,
      child: SizedBox(
        width: d,
        height: d,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            ringLayer(front: false),
            AnimatedOpacity(
              opacity: dim,
              duration: const Duration(milliseconds: 400),
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size.square(d),
                  painter: _DomePainter(clock: _clock),
                ),
              ),
            ),
            if (rings) ringLayer(front: true),
            if (widget.showLogo) _logo(d),
          ],
        ),
      ),
    );
  }
}

enum _PlanetGlow { bright, mid, dim }

class _Planet {
  final int ring;
  final double startDeg;
  final double periodSec;

  /// Radius in px for a sphere of radius 120 (scaled with the real sphere).
  final double radius;
  final _PlanetGlow glow;
  const _Planet(
    this.ring,
    this.startDeg,
    this.periodSec,
    this.radius,
    this.glow,
  );
}

/// Four concentric horizontal rings around the sphere (approved board v4,
/// D-090/D-091) with six small planets of different glow. The back half of the
/// rings is drawn under the sphere, the front half over it.
class _AuraRingsPainter extends CustomPainter {
  final _HoloClock clock;
  final double diameter;
  final bool rings;

  /// false = back layer (under the sphere), true = front layer (over it).
  final bool front;

  static const List<double> _ringFactor = [1.34, 1.56, 1.78, 2.00];
  static const List<double> _ringInclDeg = [70, 71, 72, 73];
  static const List<_Planet> _planets = [
    _Planet(0, 40, 18, 5.0, _PlanetGlow.bright),
    _Planet(1, 205, 24, 3.5, _PlanetGlow.mid),
    _Planet(1, 25, 24, 4.0, _PlanetGlow.dim),
    _Planet(2, 115, 31, 5.5, _PlanetGlow.bright),
    _Planet(3, 300, 40, 3.5, _PlanetGlow.dim),
    _Planet(3, 150, 40, 4.5, _PlanetGlow.mid),
  ];

  _AuraRingsPainter({
    required this.clock,
    required this.diameter,
    required this.rings,
    required this.front,
  }) : super(repaint: clock);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = diameter / 2;
    final k = r / 120.0;
    final listening = clock.state == Gate3InteractionState.listening;

    // Back layer only: a faint aura while Sedi listens (flat theme otherwise).
    if (!front && listening) {
      final breath = 0.975 + 0.025 * math.sin(clock.breath);
      final auraR = r * 1.62 * breath;
      canvas.drawCircle(
        c,
        auraR,
        Paint()
          ..shader = RadialGradient(
            colors: [
              SediPalette.pistachio500.withOpacity(0.35),
              SediPalette.pistachio500.withOpacity(0.0),
            ],
            stops: const [0.4, 0.68],
          ).createShader(Rect.fromCircle(center: c, radius: auraR)),
      );
    }

    if (!rings) return;

    // Speaking: the ring glow pulses gently with Sedi's voice.
    final pulse = clock.state == Gate3InteractionState.speaking
        ? 0.85 + 0.15 * math.sin(clock.pulse)
        : 1.0;

    for (var i = 0; i < _ringFactor.length; i++) {
      final rx = r * _ringFactor[i];
      final ry = rx * math.cos(_ringInclDeg[i] * math.pi / 180.0);
      final oval = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);
      // Flutter arcs run clockwise on screen: 0..pi is the lower (near) half.
      final start = front ? 0.0 : math.pi;
      canvas.drawArc(
        oval,
        start,
        math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(3.0, (front ? 6.0 : 5.0) * k)
          ..color = SediPalette.pistachio500.withOpacity(
            (front ? 0.45 : 0.22) * pulse,
          ),
      );
      canvas.drawArc(
        oval,
        start,
        math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, (front ? 1.8 : 1.4) * k)
          ..color = SediPalette.pistachio900.withOpacity(front ? 0.70 : 0.34),
      );
    }

    for (final pl in _planets) {
      final a =
          (pl.startDeg * math.pi / 180.0) +
          2 * math.pi * clock.orbitSec / pl.periodSec;
      final sinA = math.sin(a);
      final isFront = sinA >= 0;
      if (isFront != front) continue;
      final rx = r * _ringFactor[pl.ring];
      final incl = _ringInclDeg[pl.ring] * math.pi / 180.0;
      final ry = rx * math.cos(incl);
      final p = c + Offset(rx * math.cos(a), ry * sinA);
      // Depth cue: nearer planets are slightly larger.
      final zn = sinA * math.sin(incl);
      _planet(canvas, p, pl.radius * k * (1 + 0.28 * zn), pl.glow);
    }
  }

  void _planet(Canvas canvas, Offset p, double rad, _PlanetGlow glow) {
    final haloMul = switch (glow) {
      _PlanetGlow.bright => 4.2,
      _PlanetGlow.mid => 3.2,
      _PlanetGlow.dim => 2.2,
    };
    final haloColor = glow == _PlanetGlow.dim
        ? SediPalette.pistachio700
        : SediPalette.pistachio500;
    final haloAlpha = switch (glow) {
      _PlanetGlow.bright => 0.85,
      _PlanetGlow.mid => 0.55,
      _PlanetGlow.dim => 0.30,
    };
    final haloR = rad * haloMul;
    canvas.drawCircle(
      p,
      haloR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            haloColor.withOpacity(haloAlpha),
            haloColor.withOpacity(haloAlpha * 0.35),
            haloColor.withOpacity(0.0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: p, radius: haloR)),
    );
    final colors = switch (glow) {
      _PlanetGlow.bright => const [
        SediPalette.shell100,
        SediPalette.pistachio300,
        SediPalette.pistachio700,
        SediPalette.pistachio900,
      ],
      _PlanetGlow.mid => const [
        SediPalette.pistachio100,
        SediPalette.pistachio500,
        Color(0xFF5F6F26),
        SediPalette.pistachio900,
      ],
      _PlanetGlow.dim => const [
        SediPalette.pistachio500,
        Color(0xFF6E7D2A),
        SediPalette.pistachio900,
        SediPalette.pistachio900,
      ],
    };
    canvas.drawCircle(
      p,
      rad,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.32, -0.4),
          radius: 0.8,
          colors: colors,
          stops: const [0.0, 0.4, 0.85, 1.0],
        ).createShader(Rect.fromCircle(center: p, radius: rad)),
    );
    canvas.drawCircle(
      p + Offset(-rad * 0.32, -rad * 0.34),
      rad * 0.22,
      Paint()..color = Colors.white.withOpacity(0.85),
    );
  }

  @override
  bool shouldRepaint(covariant _AuraRingsPainter oldDelegate) =>
      oldDelegate.diameter != diameter ||
      oldDelegate.rings != rings ||
      oldDelegate.front != front;
}

class _DomePainter extends CustomPainter {
  final _HoloClock clock;

  _DomePainter({required this.clock}) : super(repaint: clock);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final rect = Rect.fromCircle(center: c, radius: r);

    canvas.save();
    if (clock.state == Gate3InteractionState.speaking) {
      final s = 1.0 + 0.022 * math.sin(clock.pulse);
      canvas.translate(c.dx, c.dy);
      canvas.scale(s);
      canvas.translate(-c.dx, -c.dy);
    }

    canvas.save();
    canvas.clipPath(Path()..addOval(rect));

    canvas.drawRect(rect, Paint()..color = SediPalette.pistachio700);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.30, -0.42),
          radius: 1.15,
          colors: const [
            SediPalette.shell100,
            SediPalette.pistachio100,
            SediPalette.pistachio300,
            SediPalette.pistachio500,
            SediPalette.pistachio700,
          ],
          stops: const [0.0, 0.16, 0.40, 0.70, 1.0],
        ).createShader(rect),
    );

    // Holographic sweep (light), rotating.
    final speedUp = clock.state == Gate3InteractionState.thinking;
    final sweep = SweepGradient(
      colors: [
        Colors.white.withOpacity(0.0),
        Colors.white.withOpacity(0.34),
        SediPalette.pistachio100.withOpacity(0.30),
        Colors.white.withOpacity(0.0),
        SediPalette.pistachio300.withOpacity(0.30),
        Colors.white.withOpacity(0.22),
        Colors.white.withOpacity(0.0),
      ],
      stops: const [0.0, 0.17, 0.33, 0.5, 0.67, 0.83, 1.0],
      transform: GradientRotation(clock.holoTurns * 2 * math.pi),
    );
    canvas.drawRect(
      rect.inflate(r * 0.2),
      Paint()
        ..shader = sweep.createShader(rect)
        ..blendMode = BlendMode.screen
        ..colorFilter = ColorFilter.mode(
          Colors.white.withOpacity(speedUp ? 0.95 : 0.70),
          BlendMode.modulate,
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.08),
    );

    // Glass depth: darker olive toward the lower-right rim.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.35, 0.50),
          radius: 0.95,
          colors: [
            SediPalette.pistachio900.withOpacity(0.0),
            SediPalette.pistachio900.withOpacity(0.46),
          ],
          stops: const [0.50, 1.0],
        ).createShader(rect),
    );

    // Reflected light from below (gives the sphere volume) and a soft rim.
    final bounce = Rect.fromCenter(
      center: Offset(c.dx - r * 0.02, c.dy + r * 0.68),
      width: r * 0.90,
      height: r * 0.56,
    );
    canvas.drawOval(
      bounce,
      Paint()
        ..shader = RadialGradient(
          colors: [
            SediPalette.pistachio300.withOpacity(0.75),
            SediPalette.pistachio300.withOpacity(0.0),
          ],
        ).createShader(bounce),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            SediPalette.pistachio900.withOpacity(0.0),
            SediPalette.pistachio900.withOpacity(0.30),
          ],
          stops: const [0.60, 1.0],
        ).createShader(rect),
    );
    canvas.restore();

    canvas.drawCircle(
      c,
      r - 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = SediPalette.pistachio900.withOpacity(0.22),
    );

    // Specular highlight.
    canvas.save();
    canvas.translate(c.dx - r * 0.30, c.dy - r * 0.60);
    canvas.rotate(-0.42);
    final spec = Rect.fromCenter(
      center: Offset.zero,
      width: r * 0.72,
      height: r * 0.40,
    );
    canvas.drawOval(
      spec,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.85),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(spec),
    );
    canvas.restore();

    // Listening ripples (pistachio).
    if (clock.state == Gate3InteractionState.listening) {
      for (var k = 0; k < 2; k++) {
        final p = (clock.ripple + k * 0.5) % 1.0;
        canvas.drawCircle(
          c,
          r * (1.0 + 0.7 * p),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = SediPalette.pistachio700.withOpacity((1 - p) * 0.55),
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DomePainter oldDelegate) => false;
}
