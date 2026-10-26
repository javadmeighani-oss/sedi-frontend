import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/sedi_palette.dart';
import '../../models/gate3_interaction_state.dart';
import 'sedi_presence_tokens.dart';

/// Horizontal resonance line (D-091/D-097): a fine sound-waveform line with an
/// echo, tallest at the centre under the hologram and fading to the screen
/// edges (replaces the chunky bar columns).
///
/// Four states, four motions (state authority = [Gate3InteractionState]):
///  - idle      = Sedi SEES / watches: an almost flat line with a faint shimmer;
///  - listening = Sedi HEARS: sound swells arrive from both edges to the centre;
///  - thinking  = Sedi THINKS: a short wave packet scans left and right;
///  - speaking  = Sedi SPEAKS: syllable-like bursts flow out from the centre.
/// States cross-fade smoothly. Deterministic — no per-frame random noise, no
/// scribble path, and no ECG/medical grammar. Visual-only; not I9,
/// microphone amplitude, or physiology.
/// State authority is [Gate3InteractionState] (same as circular ring).
///
/// When [phaseListenable] is provided, phase advances from that shared
/// listenable so left/right segments stay synchronized.
class SediHorizontalResonanceVisualizer extends StatefulWidget {
  final Gate3InteractionState state;

  /// Optional shared phase source (0..1). When null, owns a local controller.
  final Animation<double>? phaseListenable;

  /// Bars drawn in this segment. Defaults to [barCount].
  final int? segmentBarCount;

  /// Global bar index of the first bar in this segment (keeps envelope continuous).
  final int globalBarOffset;

  /// Total bars across the full presence (used with [globalBarOffset]).
  final int? globalBarTotal;

  static const double height = SediPresenceTokens.visualizerHeight;
  static const int barCount = 98;
  static const double phaseSpeed = 0.85;
  static const double amplitudeScale = SediPresenceTokens.amplitudeScale;

  /// Previous speaking heightFactor peak (energy 0.92 × full envelope).
  static const double previousSpeakingPeak = 0.98;

  /// Hard ceiling after state energy. ~35% below [previousSpeakingPeak].
  static const double peakCeiling = 0.65;

  static double targetEnergy(Gate3InteractionState state) {
    switch (state) {
      case Gate3InteractionState.idle:
        return 0.08;
      case Gate3InteractionState.listening:
        return 0.28;
      case Gate3InteractionState.thinking:
        return 0.52;
      case Gate3InteractionState.speaking:
        return 0.92;
    }
  }

  /// Deterministic audio/voice resonance in `0..1`.
  /// Visual-only. Not microphone, I9, heart-rate, or clinical data.
  ///
  /// Orb-centered mirror: equal distance from 0.5 yields the same shape.
  /// Shared [phase01] on both sides. Broad traveling sine clusters with
  /// soft interference. No impulse, sharp spike, or per-frame noise.
  static double audioResonanceShape(
    double relativeX,
    double phase01, [
    double density = 1.0,
  ]) {
    final x = relativeX - relativeX.floorToDouble();
    final p = phase01 - phase01.floorToDouble();
    // 0 at the orb/centerline, 1 at either outer edge.
    final centerDistance = (x - 0.5).abs() * 2.0;
    final travel = (centerDistance - p) - (centerDistance - p).floorToDouble();

    // Integer cycles in radial distance so wrap stays continuous.
    final humpA = 0.5 + 0.5 * math.sin(travel * math.pi * 4.0);
    final humpB = 0.5 + 0.5 * math.sin((travel + 0.27) * math.pi * 2.0);
    final humpC = 0.5 +
        0.5 * math.sin((centerDistance * math.pi * 2.0) + (p * math.pi * 2.0));
    final mix = 0.42 * humpA + 0.33 * humpB + 0.25 * humpC;

    final bell = math.exp(-math.pow((centerDistance - 0.42) / 0.58, 2));
    final lifted = mix * (0.78 + 0.22 * bell);
    final contrast = 0.55 + 0.45 * density.clamp(0.0, 1.0);
    return (0.12 + lifted * contrast).clamp(0.0, 1.0).toDouble();
  }

  static double heightFactorFor({
    required double energy,
    required double envelope,
    required double density,
  }) {
    final raw = 0.06 + energy * envelope * (0.35 + 0.65 * density);
    return math.min(raw, peakCeiling).clamp(0.06, peakCeiling).toDouble();
  }

  const SediHorizontalResonanceVisualizer({
    super.key,
    required this.state,
    this.phaseListenable,
    this.segmentBarCount,
    this.globalBarOffset = 0,
    this.globalBarTotal,
  });

  @override
  State<SediHorizontalResonanceVisualizer> createState() =>
      _SediHorizontalResonanceVisualizerState();
}

class _SediHorizontalResonanceVisualizerState
    extends State<SediHorizontalResonanceVisualizer>
    with SingleTickerProviderStateMixin {
  AnimationController? _ownedController;
  double _energy = SediHorizontalResonanceVisualizer.targetEnergy(
      Gate3InteractionState.idle);

  /// Cross-fade weights per state: idle, listening, thinking, speaking.
  final List<double> _weights = [1.0, 0.0, 0.0, 0.0];

  Animation<double> get _phase => widget.phaseListenable ?? _ownedController!;

  static int _index(Gate3InteractionState state) {
    switch (state) {
      case Gate3InteractionState.idle:
        return 0;
      case Gate3InteractionState.listening:
        return 1;
      case Gate3InteractionState.thinking:
        return 2;
      case Gate3InteractionState.speaking:
        return 3;
    }
  }

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _weights.length; i++) {
      _weights[i] = i == _index(widget.state) ? 1.0 : 0.0;
    }
    if (widget.phaseListenable == null) {
      _ownedController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 10),
      )
        ..addListener(_tick)
        ..repeat();
    } else {
      widget.phaseListenable!.addListener(_tick);
    }
  }

  @override
  void didUpdateWidget(covariant SediHorizontalResonanceVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phaseListenable != widget.phaseListenable) {
      oldWidget.phaseListenable?.removeListener(_tick);
      if (widget.phaseListenable == null && _ownedController == null) {
        _ownedController = AnimationController(
          vsync: this,
          duration: const Duration(seconds: 10),
        )
          ..addListener(_tick)
          ..repeat();
      } else if (widget.phaseListenable != null) {
        _ownedController?.removeListener(_tick);
        _ownedController?.dispose();
        _ownedController = null;
        widget.phaseListenable!.addListener(_tick);
      }
    }
    if (oldWidget.state != widget.state) {
      _tick();
    }
  }

  void _tick() {
    if (!mounted) return;
    final target = SediHorizontalResonanceVisualizer.targetEnergy(widget.state);
    final active = _index(widget.state);
    setState(() {
      _energy = _energy + (target - _energy) * 0.12;
      for (var i = 0; i < _weights.length; i++) {
        final goal = i == active ? 1.0 : 0.0;
        _weights[i] += (goal - _weights[i]) * 0.10;
      }
    });
  }

  @override
  void dispose() {
    widget.phaseListenable?.removeListener(_tick);
    _ownedController?.removeListener(_tick);
    _ownedController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count =
        widget.segmentBarCount ?? SediHorizontalResonanceVisualizer.barCount;
    return SizedBox(
      width: double.infinity,
      height: SediHorizontalResonanceVisualizer.height,
      child: CustomPaint(
        painter: _ResonanceLinePainter(
          phase: _phase.value,
          energy: _energy,
          wIdle: _weights[0],
          wListen: _weights[1],
          wThink: _weights[2],
          wSpeak: _weights[3],
          samples: math.max(48, count * 2),
          globalBarOffset: widget.globalBarOffset,
          globalBarTotal: widget.globalBarTotal ??
              SediHorizontalResonanceVisualizer.barCount,
        ),
      ),
    );
  }
}

/// Draws the resonance line like a sound waveform (D-097): a fine, smooth
/// audio-style line made of several carrier waves, with an echo line and a
/// faint glow. The four states change how the sound "behaves":
///  - idle      (sees)   : almost flat, only a tiny shimmer;
///  - listening (hears)  : waves arrive from both edges towards the centre;
///  - thinking           : a short wave packet scans left and right;
///  - speaking           : syllable-like bursts flow outward from the centre.
///
/// `phase` loops 0..1 every 10 s; every temporal frequency is an integer
/// number of cycles per loop, so the motion wraps without a jump.
class _ResonanceLinePainter extends CustomPainter {
  final double phase;
  final double energy;
  final double wIdle;
  final double wListen;
  final double wThink;
  final double wSpeak;
  final int samples;
  final int globalBarOffset;
  final int globalBarTotal;

  static const _presence = SediPresenceTokens.presenceGreen;
  static const double _tau = 2 * math.pi;

  const _ResonanceLinePainter({
    required this.phase,
    required this.energy,
    required this.wIdle,
    required this.wListen,
    required this.wThink,
    required this.wSpeak,
    required this.samples,
    required this.globalBarOffset,
    required this.globalBarTotal,
  });

  /// Sound-like carrier at [x] (0..1) in -1..1: four sines of different
  /// pitch, so the line looks like an audio waveform rather than a ribbon.
  double _carrier(double x, double p, double shift) {
    final v = 0.55 * math.sin(_tau * (9.0 * x + 3 * p + shift)) +
        0.35 * math.sin(_tau * (17.0 * x - 5 * p + 0.13 + shift)) +
        0.25 * math.sin(_tau * (31.0 * x + 7 * p + 0.31 + shift)) +
        0.18 * math.sin(_tau * (47.0 * x - 11 * p + 0.57));
    return v / 1.05;
  }

  /// Amplitude (0..1) of the line at [x] for the current state mix.
  double _amplitude(double x) {
    final d = ((x - 0.5).abs() * 2.0).clamp(0.0, 1.0).toDouble();
    final env = math.exp(-math.pow(d / 0.78, 2)).toDouble();
    final p = phase;

    // Sees: a faint shimmer that breathes.
    final idle = 0.09 * (1.0 + 0.4 * math.sin(_tau * p));

    // Hears: swells travel in from the edges to the centre.
    final listen = 0.52 * (0.55 + 0.45 * math.sin(_tau * (2.2 * d + 4 * p)));

    // Thinks: a short packet sweeps left and right over a quiet line.
    final c = 0.5 + 0.38 * math.sin(_tau * 2 * p);
    final packet = math.exp(-math.pow((x - c) / 0.14, 2)).toDouble();
    final think = 0.10 + 0.70 * packet;

    // Speaks: syllable bursts flowing outward from the centre.
    final burst = math.sin(_tau * (5 * p - 1.4 * d));
    final speak = 1.0 *
        (0.35 + 0.65 * burst * burst) *
        (0.75 +
            0.25 *
                SediHorizontalResonanceVisualizer.audioResonanceShape(
                  x,
                  p,
                  0.8,
                ));

    final mix =
        wIdle * idle + wListen * listen + wThink * think + wSpeak * speak;
    return (mix * env).clamp(0.0, 1.0).toDouble();
  }

  double _globalX(double x) => globalBarTotal <= 1
      ? 0.5
      : (globalBarOffset + x * (globalBarTotal - 1)) / (globalBarTotal - 1);

  Path _line(Size size, double shift, double scale) {
    final midY = size.height / 2;
    final amp =
        midY * 0.92 * (SediHorizontalResonanceVisualizer.amplitudeScale / 0.8);
    final n = math.max(samples, (size.width / 2).ceil());
    final pts = <Offset>[];
    for (var i = 0; i <= n; i++) {
      final x = i / n;
      final gx = _globalX(x);
      final level =
          (_carrier(gx, phase, shift) * _amplitude(gx)).clamp(-1.0, 1.0);
      final y = midY - level * amp * scale;
      pts.add(Offset(size.width * x, y));
    }
    // Smooth curve through the mid-points (no angular kinks).
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length - 1; i++) {
      final mid = Offset(
        (pts[i].dx + pts[i + 1].dx) / 2,
        (pts[i].dy + pts[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    return path;
  }

  Shader _fade(Size size, Color color, double alpha) => LinearGradient(
        colors: [
          color.withOpacity(0.0),
          color.withOpacity(alpha),
          color.withOpacity(alpha),
          color.withOpacity(0.0),
        ],
        stops: const [0.0, 0.10, 0.90, 1.0],
      ).createShader(Offset.zero & size);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || samples < 2) return;
    final mainAlpha =
        (0.70 * SediPresenceTokens.barOpacityScale).clamp(0.0, 1.0).toDouble();

    Paint stroke(double width, Shader shader) => Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = width
      ..shader = shader;

    final main = _line(size, 0.0, 1.0);
    final echo = _line(size, 0.11, 0.72);

    // Faint echo line behind, then a soft glow, then the crisp main line.
    canvas.drawPath(
      echo,
      stroke(1.0, _fade(size, SediPalette.pistachio700, 0.55)),
    );
    canvas.drawPath(
      main,
      stroke(5.0, _fade(size, SediPalette.pistachio500, 0.28))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(main, stroke(1.5, _fade(size, _presence, mainAlpha)));
  }

  @override
  bool shouldRepaint(covariant _ResonanceLinePainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.energy != energy ||
      oldDelegate.wIdle != wIdle ||
      oldDelegate.wListen != wListen ||
      oldDelegate.wThink != wThink ||
      oldDelegate.wSpeak != wSpeak ||
      oldDelegate.samples != samples ||
      oldDelegate.globalBarOffset != globalBarOffset ||
      oldDelegate.globalBarTotal != globalBarTotal;
}
