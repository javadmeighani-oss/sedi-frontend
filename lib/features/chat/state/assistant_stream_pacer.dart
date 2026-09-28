import 'dart:async';

/// UI-only reveal cadence for assistant stream chunks.
///
/// Backend/SSE chunk order is unchanged. This only spaces paints so the
/// on-screen reveal is about [speedFactor] of the previous frame-yield speed.
class AssistantStreamPacer {
  /// 1.0 was the original ~1-frame yield. 0.30 is ~50% slower than the
  /// prior 0.60 cadence (~53ms between consecutive paints).
  static const double speedFactor = 0.30;
  static const Duration previousYield = Duration(milliseconds: 16);

  static Duration get revealDelay => Duration(
        microseconds:
            (previousYield.inMicroseconds / speedFactor).round(),
      );

  final List<_QueuedChunk> _queue = <_QueuedChunk>[];
  Completer<void> _idle = Completer<void>()..complete();
  bool _running = false;
  bool _cancelled = false;
  bool _hasPainted = false;
  DateTime? _lastPaintAt;

  bool get isIdle => !_running && _queue.isEmpty;

  Future<void> get whenIdle => _idle.future;

  void enqueue(String chunk, void Function(String chunk) apply) {
    if (_cancelled || chunk.isEmpty) return;
    _queue.add(_QueuedChunk(chunk, apply));
    if (_idle.isCompleted) {
      _idle = Completer<void>();
    }
    _drain();
  }

  Future<void> _waitForCadence() async {
    if (!_hasPainted || _lastPaintAt == null) return;
    final remaining = revealDelay - DateTime.now().difference(_lastPaintAt!);
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
  }

  Future<void> _drain() async {
    if (_running) return;
    _running = true;
    while (_queue.isNotEmpty && !_cancelled) {
      await _waitForCadence();
      if (_cancelled || _queue.isEmpty) continue;
      final next = _queue.removeAt(0);
      next.apply(next.chunk);
      _hasPainted = true;
      _lastPaintAt = DateTime.now();
    }
    _running = false;
    if (!_idle.isCompleted) {
      _idle.complete();
    }
  }

  void cancel() {
    _cancelled = true;
    _queue.clear();
    if (!_idle.isCompleted) {
      _idle.complete();
    }
  }
}

class _QueuedChunk {
  final String chunk;
  final void Function(String chunk) apply;

  const _QueuedChunk(this.chunk, this.apply);
}
