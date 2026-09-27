import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/gate3_interaction_state.dart';
import 'sedi_presence_tokens.dart';

/// Horizontal anti-aliased bar-column resonance visualizer.
///
/// Deterministic clustered motion — no per-frame random noise.
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

  /// Deterministic lub-dub pulse on [phase01] in `0..1`. Two peaks, then rest.
  static double heartbeatEnvelope(double phase01) {
    final p = phase01 - phase01.floorToDouble();
    return (_lubDub(p, 0.00, 0.16) + _lubDub(p, 0.18, 0.12) * 0.62)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  static double _lubDub(double p, double start, double width) {
    final t = p - start;
    if (t < 0 || t > width) return 0;
    final x = t / width;
    return math.sin(x * math.pi) * math.exp(-x * 1.8);
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
    final barWidth = (pitch * 0.38).clamp(1.0, 1.8).toDouble();
    final midY = size.height / 2;
    final maxHalf = size.height * 0.50;
    final cycle =
        (phase * SediHorizontalResonanceVisualizer.phaseSpeed) % 1.0;
    final beat = SediHorizontalResonanceVisualizer.heartbeatEnvelope(cycle);
    final total = math.max(globalBarTotal, 1);

    final paint = Paint()
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = barWidth;

    for (var i = 0; i < count; i++) {
      final globalIndex = globalBarOffset + i;
      final t = total <= 1 ? 0.5 : globalIndex / (total - 1);
      // Soft center dome — bars pulse together, not independently scribbled.
      final spatial = 0.72 + 0.28 * math.sin(t * math.pi);
      final envelope = 0.22 + beat * 0.78;

      // Idle stays near-flat; speaking gets largest controlled variation.
      final variation = 0.18 + density * 0.82;
      final heightFactor = (0.10 + energy * (0.32 + envelope * variation) * spatial)
          .clamp(0.06, 1.0)
          .toDouble();
      final half = maxHalf *
          heightFactor *
          SediHorizontalResonanceVisualizer.amplitudeScale;

      final x = pitch * (i + 0.5);
      final baseOpacity =
          (0.18 + energy * 0.55 + envelope * 0.2).clamp(0.12, 0.92).toDouble();
      final finalOpacity =
          (baseOpacity * SediPresenceTokens.barOpacityScale).clamp(0.0, 1.0);
      paint.color = _presence.withOpacity(finalOpacity);

      canvas.drawLine(
        Offset(x, midY - half),
        Offset(x, midY + half),
        paint,
      );
    }
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
