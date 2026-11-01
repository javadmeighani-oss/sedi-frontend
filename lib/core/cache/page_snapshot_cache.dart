/// Last-seen content of the pages behind the top icons (Javad 2026-11-01: their sections took long to load).
///
/// A page paints the snapshot of its previous visit AT ONCE and refreshes behind it, so the user never waits on a spinner
/// for something already known. In-memory only (nothing is written to disk), per app run, expires after [maxAge], and is
/// cleared on logout / invalid session so one user's content never reaches another. Fail-open: a miss shows the page as
/// before (spinner, then content).
class PageSnapshotCache {
  PageSnapshotCache._();

  static const Duration maxAge = Duration(minutes: 30);

  static final Map<String, _Entry> _entries = <String, _Entry>{};

  static T? get<T>(String key, {DateTime? now}) {
    final e = _entries[key];
    if (e == null) return null;
    if ((now ?? DateTime.now()).difference(e.at) > maxAge) {
      _entries.remove(key);
      return null;
    }
    final v = e.value;
    return v is T ? v : null;
  }

  static void put(String key, Object value, {DateTime? now}) {
    _entries[key] = _Entry(value, now ?? DateTime.now());
  }

  static void clear() => _entries.clear();

  static const String schedule = 'lifestyle.schedule';
  static const String health = 'lifestyle.health';
  static const String history = 'lifestyle.history';
  static const String inbox = 'inbox.first_page';
}

class _Entry {
  final Object value;
  final DateTime at;
  const _Entry(this.value, this.at);
}
