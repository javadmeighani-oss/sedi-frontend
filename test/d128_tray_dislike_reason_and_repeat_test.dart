import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/lifestyle/presentation/lifestyle_l10n.dart';
import 'package:sedi_app/services/lifestyle/lifestyle_schedule_service.dart';

/// DEBT-044: repeating reminders show their rhythm. (The P7 "remember a tray dislike and ask in the chat sheet" tests were
/// retired by R-073: Sedi now asks the reason herself in her first chat message, in ONE place - see
/// f2_quick_reply_and_reason_panel_test.dart.)
void main() {
  test('the tray handler no longer stores a dislike for a chat sheet; the backend asks the reason in the first message', () {
    final bg = File('lib/core/notifications/background_notification_action_handler.dart').readAsStringSync();
    expect(bg.contains("action == 'dislike'"), isTrue);
    expect(bg.contains('PendingDislikeReasons'), isFalse);
    final page = File('lib/features/gate3_interactive/presentation/pages/gate3_interactive_page.dart').readAsStringSync();
    expect(page.contains('_askPendingDislikeReason'), isFalse);
    final inbox = File('lib/features/notifications/presentation/pages/notification_inbox_page.dart').readAsStringSync();
    expect(inbox.contains('showDislikeReasonSheet('), isTrue);
  });

  test('the schedule event keeps its repeat rule and labels it in every language', () {
    final e = LifestyleUserEventDto.fromJson({
      'id': 7,
      'title': 'آب بخورم',
      'status': 'scheduled',
      'starts_at': '2026-10-28T08:00:00',
      'recurrence_rule': 'FREQ=DAILY',
      'source': 'conversation',
    });
    expect(e.recurrenceRule, 'FREQ=DAILY');
    expect(
      LifestyleUserEventDto.fromJson({'id': 1, 'title': 'x', 'status': 'scheduled'}).recurrenceRule,
      isNull,
    );
    expect(
      LifestyleUserEventDto.fromJson({
        'id': 1,
        'title': 'x',
        'status': 'scheduled',
        'recurrence_rule': 'garbage',
      }).recurrenceRule,
      isNull,
    );

    final fa = LifestyleL10n('fa');
    final en = LifestyleL10n('en');
    final ar = LifestyleL10n('ar');
    expect(fa.repeatLabel('FREQ=DAILY', '2026-10-28T08:00:00'), 'هر روز · 08:00');
    expect(en.repeatLabel('FREQ=DAILY', '2026-10-28T08:00:00'), 'Every day · 08:00');
    expect(ar.repeatLabel('FREQ=DAILY', '2026-10-28T08:00:00'), 'كل يوم · 08:00');
    expect(fa.repeatLabel('FREQ=WEEKLY;BYDAY=MO', '2026-11-02T10:00:00'), 'هر دوشنبه · 10:00');
    expect(en.repeatLabel('FREQ=WEEKLY;BYDAY=SU', null), 'Every Sunday');
    expect(fa.repeatLabel(null, '2026-10-28T08:00:00'), isNull);
  });
}
