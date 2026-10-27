/// What Sedi remembers about the user — mirrors GET /memory/overview (R-021 / M1).
class MemoryFact {
  const MemoryFact({
    required this.id,
    required this.key,
    required this.value,
    required this.editable,
  });

  final int id;
  final String key;
  final String value;
  final bool editable;

  static MemoryFact? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final id = m['id'];
    if (id is! int) return null;
    return MemoryFact(
      id: id,
      key: (m['key'] ?? '').toString(),
      value: (m['value'] ?? '').toString(),
      editable: m['editable'] == true,
    );
  }
}

class MemoryTimelineEvent {
  const MemoryTimelineEvent({
    required this.id,
    required this.kind,
    required this.title,
    this.occurredAt,
  });

  final int id;
  final String kind;
  final String title;
  final String? occurredAt;

  /// The date part only, e.g. 2026-10-24.
  String get dateLabel {
    final v = occurredAt;
    if (v == null || v.length < 10) return '';
    return v.substring(0, 10);
  }

  static MemoryTimelineEvent? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final id = m['id'];
    if (id is! int) return null;
    return MemoryTimelineEvent(
      id: id,
      kind: (m['kind'] ?? '').toString(),
      title: (m['title'] ?? '').toString(),
      occurredAt: m['occurred_at']?.toString(),
    );
  }
}

class MemoryOverview {
  const MemoryOverview({
    required this.consent,
    required this.summary,
    required this.facts,
    required this.timeline,
  });

  final bool consent;
  final String summary;
  final List<MemoryFact> facts;
  final List<MemoryTimelineEvent> timeline;

  static MemoryOverview? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final facts = <MemoryFact>[];
    final rawFacts = m['facts'];
    if (rawFacts is List) {
      for (final f in rawFacts) {
        final p = MemoryFact.tryParse(f);
        if (p != null) facts.add(p);
      }
    }
    final events = <MemoryTimelineEvent>[];
    final rawEvents = m['timeline'];
    if (rawEvents is List) {
      for (final e in rawEvents) {
        final p = MemoryTimelineEvent.tryParse(e);
        if (p != null) events.add(p);
      }
    }
    return MemoryOverview(
      consent: m['consent'] == true,
      summary: (m['summary'] ?? '').toString(),
      facts: facts,
      timeline: events,
    );
  }
}
