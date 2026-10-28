import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/sedi_palette.dart';
import '../../models/gate3_interaction_state.dart';
import 'sedi_presence_tokens.dart';

/// Horizontal resonance (D-101): a neat sound spectrum of thin vertical lines on a
/// regular grid (reference: a voice waveform), tallest at the centre under the
/// hologram and tapering to dots at the screen edges.
///
/// Four states, four motions (state authority = [Gate3InteractionState]):
///  - idle      = Sedi SEES / watches: nearly flat, tiny breathing ticks;
///  - listening = Sedi HEARS: wide, slow swells flow out from the centre;
///  - thinking  = Sedi THINKS: soft pulses leave the centre one after another;
///  - speaking  = Sedi SPEAKS: syllable-like bursts flow out from the centre.
/// D-130: every state moves from the centre outwards (a voice leaving a mouth), never inwards.
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

  /// Painted height; defaults to [height]. The docked strip above the composer (D-102) is a little shorter.
  final double? heightOverride;

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
    this.heightOverride,
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
      height: widget.heightOverride ?? SediHorizontalResonanceVisualizer.height,
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

/// Draws the resonance as a neat SOUND SPECTRUM (D-101, reference: a voice waveform): thin vertical lines on a
/// regular grid, tallest at the centre and tapering to dots at the edges, a faint centre axis and a few glowing
/// tips. The four states change how the sound behaves:
///  - idle      (sees)   : a calm resting spectrum whose soft swells leave the centre outwards;
///  - listening (hears)  : wide, slow swells flow from the centre to the sides;
///  - thinking           : soft pulses leave the centre one after another;
///  - speaking           : syllable-like bursts flow outward from the centre.
///
/// Every line has its own fixed "character" (deterministic, not random per frame) and every temporal frequency is an
/// integer number of cycles per 10 s loop, so the motion wraps without a jump.
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

  /// Distance between two lines (dp).
  static const double _pitch = 5.0;

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

  /// Stable pseudo-random value 0..1 for line [i] and channel [k] (no per-frame noise).
  static double _hash(int i, int k) {
    final v = math.sin(i * 12.9898 + k * 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  double _globalX(double x) => globalBarTotal <= 1
      ? 0.5
      : (globalBarOffset + x * (globalBarTotal - 1)) / (globalBarTotal - 1);

  /// Height 0..1 of line [i] at relative position [x] (0..1) for the current state mix.
  double _level(int i, double x) {
    final d = ((x - 0.5).abs() * 2.0).clamp(0.0, 1.0).toDouble();
    // Bell envelope with a small floor so the edges taper to dots, not to nothing.
    final env = 0.05 + 0.95 * math.exp(-math.pow(d / 0.58, 2)).toDouble();
    final p = phase;

    // Each line has its own fixed character and a slow personal flutter.
    final base = 0.30 + 0.70 * _hash(i, 1);
    final k = 1 + (_hash(i, 2) * 4).floor(); // 1..4 cycles per loop
    final flutter = 0.72 + 0.28 * math.sin(_tau * (k * p + _hash(i, 3)));

    // Sees: a calm resting spectrum (D-102). D-130: even at rest the soft swells travel from the CENTRE outwards, like a
    // voice leaving the mouth - never from the edges to the middle.
    final idle = (0.30 + 0.10 * math.sin(_tau * (2 * p - 1.1 * d + 0.25 * _hash(i, 4)))) *
        (0.40 + 0.60 * _hash(i, 1));

    // Hears: swells now also radiate from the centre outwards (D-130, Javad: the resonance goes from the centre to the
    // sides like a mouth); listening differs from speaking by slower, wider swells.
    final s1 = math.sin(_tau * (3 * p - 1.6 * d));
    final listen = 0.22 + 0.78 * s1 * s1;

    // Thinks: soft pulses leave the centre one after another (no left/right sloshing).
    final pulse = 0.5 + 0.5 * math.sin(_tau * (2 * p - 1.0 * d));
    final think = 0.14 + 0.86 * pulse * pulse;

    // Speaks: syllable bursts flowing outward from the centre.
    final s2 = math.sin(_tau * (5 * p - 1.2 * d));
    final speak = (0.30 + 0.70 * s2 * s2) *
        (0.80 +
            0.20 *
                SediHorizontalResonanceVisualizer.audioResonanceShape(
                  x,
                  p,
                  0.8,
                ));

    // Idle keeps its own tiny ticks; the active states are shaped by each line's own character.
    final active = wListen * listen + wThink * think + wSpeak * speak;
    final shaped = wIdle * idle + active * base * flutter;
    return (env * shaped).clamp(0.0, 1.0).toDouble();
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
    if (size.width <= 0) return;
    final midY = size.height / 2;
    final maxHalf =
        midY * 0.92 * (SediHorizontalResonanceVisualizer.amplitudeScale / 0.8);
    final n = math.max(8, (size.width / _pitch).floor());
    final pitch = size.width / n;
    final mainAlpha =
        (0.70 * SediPresenceTokens.barOpacityScale).clamp(0.0, 1.0).toDouble();

    // Faint centre axis.
    canvas.drawLine(
      Offset(0, midY),
      Offset(size.width, midY),
      Paint()
        ..strokeWidth = 0.8
        ..shader = _fade(size, _presence, 0.32),
    );

    final lines = Path();
    final tips = <Offset>[];
    final glow = <Offset>[];
    for (var i = 0; i <= n; i++) {
      final x = pitch * i;
      final rel = i / n;
      final level = _level(i, _globalX(rel));
      final half = math.max(1.0, level * maxHalf);
      lines.moveTo(x, midY - half);
      lines.lineTo(x, midY + half);
      // A few tall lines carry a glowing tip, like sparks on the waveform.
      if (level > 0.30 && _hash(i, 5) > 0.74) {
        tips.add(Offset(x, midY - half));
        glow.add(Offset(x, midY + half));
      }
    }

    canvas.drawPath(
      lines,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.7
        ..shader = _fade(size, SediPalette.pistachio500, 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
    );
    canvas.drawPath(
      lines,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.1
        ..shader = _fade(size, _presence, mainAlpha),
    );

    final spark = Paint()..color = SediPalette.pistachio500.withOpacity(0.85);
    final sparkGlow = Paint()
      ..color = SediPalette.pistachio500.withOpacity(0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (final o in tips) {
      canvas.drawCircle(o, 3.2, sparkGlow);
      canvas.drawCircle(o, 1.5, spark);
    }
    for (final o in glow) {
      canvas.drawCircle(o, 1.2, spark);
    }
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
