/// What the chat does when the user comes back to the app (Javad 2026-10-30).
///
/// - A NEW day: the old thread is not kept on the first screen; Sedi welcomes the user with one fresh opener.
/// - The SAME day, after being away: that day's chats collapse into the "earlier today" card and Sedi starts with a
///   one-sentence summary.
/// - A short trip away (the keyboard picker, a permission dialog, a quick app switch) changes nothing.
enum ChatReturnAction { none, freshDay, sameDaySummary }

class ChatReturnPolicy {
  ChatReturnPolicy._();

  /// Shorter than this is not "leaving the app".
  static const Duration awayThreshold = Duration(minutes: 2);

  /// The calendar day (device time) a thread belongs to, as `YYYY-MM-DD`.
  static String dayKey(DateTime t) {
    final local = t.toLocal();
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '${local.year.toString().padLeft(4, '0')}-$m-$d';
  }

  static ChatReturnAction decide({
    required DateTime now,
    required DateTime? pausedAt,
    required String? threadDay,
    required bool hasUserMessages,
    bool busy = false,
  }) {
    if (busy || pausedAt == null) return ChatReturnAction.none;
    if (now.difference(pausedAt) < awayThreshold) return ChatReturnAction.none;
    if (threadDay != null && dayKey(now) != threadDay) return ChatReturnAction.freshDay;
    return hasUserMessages ? ChatReturnAction.sameDaySummary : ChatReturnAction.none;
  }
}
