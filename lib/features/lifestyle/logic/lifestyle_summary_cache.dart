import 'package:flutter/foundation.dart';

import '../../../services/lifestyle/lifestyle_schedule_service.dart';
import '../domain/schedule_today.dart';

/// "Today" for the Lifestyle hub (R-031), loaded ONCE and shared (Javad 2026-10-30: the hub was slow and its today card
/// came late). The three reads run together instead of one after another; A3 starts them in the background, so by the
/// time the user opens the hub the answer is usually there; a summary from earlier the same day is shown instantly
/// while the fresh one loads. Fail-open: a failure leaves the static hub.
class LifestyleSummaryCache {
  LifestyleSummaryCache._();

  static ScheduleDaySummary? _summary;
  static String? _day;
  static Future<ScheduleDaySummary?>? _inFlight;

  /// The summary of today if one was loaded today, else null (a stale one from yesterday is never shown).
  static ScheduleDaySummary? today({DateTime? now}) {
    final n = now ?? DateTime.now();
    return _day == isoDay(n) ? _summary : null;
  }

  /// Loads (or joins the load in progress) and returns the fresh summary; null when it cannot be read.
  static Future<ScheduleDaySummary?> refresh({LifestyleScheduleService? service, DateTime? now}) {
    return _inFlight ??= _load(service ?? LifestyleScheduleService(), now ?? DateTime.now()).whenComplete(() {
      _inFlight = null;
    });
  }

  static Future<ScheduleDaySummary?> _load(LifestyleScheduleService svc, DateTime now) async {
    try {
      final events = svc.listEvents();
      final meds = svc.listMedications();
      final done = svc.listDone(isoDay(now));
      final ev = await events;
      final md = await meds;
      final dn = await done;
      if (!ev.ok) return null;
      final items = buildToday(
        events: ev.data ?? const [],
        medications: md.data ?? const [],
        doneIds: dn.data ?? <String>{},
        today: now,
      );
      final summary = summarize(items, now);
      _summary = summary;
      _day = isoDay(now);
      return summary;
    } catch (e) {
      if (kDebugMode) debugPrint('[LifestyleSummaryCache] load failed: $e');
      return null;
    }
  }

  @visibleForTesting
  static void seed(ScheduleDaySummary summary, {DateTime? now}) {
    _summary = summary;
    _day = isoDay(now ?? DateTime.now());
  }

  @visibleForTesting
  static void reset() {
    _summary = null;
    _day = null;
    _inFlight = null;
  }
}
