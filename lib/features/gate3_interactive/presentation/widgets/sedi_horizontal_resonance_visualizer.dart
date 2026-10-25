import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/gate3_interaction_state.dart';
import 'sedi_presence_tokens.dart';

/// Horizontal anti-aliased bar-column resonance visualizer.
///
/// Deterministic audio/voice resonance — no per-frame random noise,
/// no scribble path, and no ECG/medical grammar. Visual-only; not I9,
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
    final travel =
        (centerDistance - p) - (centerDistance - p).floorToDouble();

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
  double _energy =
      SediHorizontalResonanceVisualizer.targetEnergy(Gate3InteractionState.idle);

  Animation<double> get _phase =>
      widget.phaseListenable ?? _ownedController!;

  static double _density(Gate3InteractionState state) {
    switch (state) {
      case Gate3InteractionState.idle:
        return 0.25;
      case Gate3InteractionState.listening:
        return 0.45;
      case Gate3InteractionState.thinking:
        return 0.70;
      case Gate3InteractionState.speaking:
        return 1.0;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.phaseListenable == null) {
      _ownedController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 10),
      )..addListener(_tick)
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
        )..addListener(_tick)
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
    final target = SediHorizontalResonanceVisualizer.targetEnergy(widget.state);
    final next = _energy + (target - _energy) * 0.12;
    if ((next - _energy).abs() > 0.0005) {
      setState(() => _energy = next);
    } else if (mounted) {
      setState(() {});
    }
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
        painter: _HorizontalResonancePainter(
          phase: _phase.value,
          energy: _energy,
          density: _density(widget.state),
          state: widget.state,
          segmentBarCount: count,
          globalBarOffset: widget.globalBarOffset,
          globalBarTotal:
              widget.globalBarTotal ?? SediHorizontalResonanceVisualizer.barCount,
        ),
      ),
    );
  }
}

class _HorizontalResonancePainter extends CustomPainter {
  final double phase;
  final double energy;
  final double density;
  final Gate3InteractionState state;
  final int segmentBarCount;
  final int globalBarOffset;
  final int globalBarTotal;

  static const _presence = SediPresenceTokens.presenceGreen;

  const _HorizontalResonancePainter({
    required this.phase,
    required this.energy,
    required this.density,
    required this.state,
    required this.segmentBarCount,
    required this.globalBarOffset,
    required this.globalBarTotal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (segmentBarCount <= 0 || size.width <= 0) return;

    final count = segmentBarCount;
    final pitch = size.width / count;
    // Delicate ~1dp hairlines with clear gaps (design boards, D-079): never
    // chunky columns, and never wider than the gap-free pitch.
    final barWidth = (pitch * 0.30).clamp(0.9, 1.3).toDouble();
    final midY = size.height / 2;
    final cycle =
        (phase * SediHorizontalResonanceVisualizer.phaseSpeed) % 1.0;
    final total = math.max(globalBarTotal, 1);
    final path = Path();

    for (var i = 0; i < count; i++) {
      final globalIndex = globalBarOffset + i;
      final relativeX = total <= 1 ? 0.5 : globalIndex / (total - 1);
      // Radial audio-resonance; left/right at equal |x-0.5| match.
      final shape = SediHorizontalResonanceVisualizer.audioResonanceShape(
        relativeX,
        cycle,
        density,
      );
      // Idle stays near-flat; speaking is strongest but hard-capped.
      final heightFactor = SediHorizontalResonanceVisualizer.heightFactorFor(
        energy: energy,
        envelope: shape,
        density: density,
      );
      // Bell envelope: tallest at the centreline (under the hologram).
      final centerDistance =
          ((relativeX - 0.5).abs() * 2.0).clamp(0.0, 1.0).toDouble();
      final bell = math.exp(-math.pow(centerDistance / 0.62, 2)).toDouble();
      final live = ((heightFactor - 0.06) /
              (SediHorizontalResonanceVisualizer.peakCeiling - 0.06))
          .clamp(0.0, 1.0)
          .toDouble();
      // Rest: ~4dp at the edges up to ~12dp at the centre; live adds up to ~24dp.
      final totalHeight = (4.0 + bell * (8.0 + 24.0 * live)) *
          (SediHorizontalResonanceVisualizer.amplitudeScale / 0.8);
      final half = math.min(totalHeight, size.height) / 2;

      final x = pitch * (i + 0.5);
      path.moveTo(x, midY - half);
      path.lineTo(x, midY + half);
    }

    // Faint halo (narrower than the pitch so bars never merge), then the
    // crisp hairlines — two draw calls for all bars.
    canvas.drawPath(
      path,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = barWidth * 2.0
        ..color = _presence.withOpacity(0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6),
    );
    final opacity =
        (0.70 * SediPresenceTokens.barOpacityScale + energy * 0.2)
            .clamp(0.0, 1.0)
            .toDouble();
    canvas.drawPath(
      path,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = barWidth
        ..color = _presence.withOpacity(opacity),
    );
  }

  @override
  bool shouldRepaint(covariant _HorizontalResonancePainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.energy != energy ||
      oldDelegate.density != density ||
      oldDelegate.state != state ||
      oldDelegate.segmentBarCount != segmentBarCount ||
      oldDelegate.globalBarOffset != globalBarOffset ||
      oldDelegate.globalBarTotal != globalBarTotal;
}
