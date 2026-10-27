import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sedi_app/core/notifications/pending_dislike_reasons.dart';
import 'package:sedi_app/features/lifestyle/presentation/lifestyle_l10n.dart';
import 'package:sedi_app/services/lifestyle/lifestyle_schedule_service.dart';

/// P7 (frontend) + DEBT-044: a tray dislike is remembered so Sedi can ask WHY once; repeating reminders show their rhythm.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    PendingDislikeReasons.prefsLoader = null;
  });

  test('a tray dislike is remembered and asked about once, oldest first', () async {
    await PendingDislikeReasons.add(12);
    await PendingDislikeReasons.add(12); // duplicate ignored
    await PendingDislikeReasons.add(15);
    expect(await PendingDislikeReasons.load(), [12, 15]);
    expect(await PendingDislikeReasons.takeNext(), 12);
    expect(await PendingDislikeReasons.takeNext(), 15);
    expect(await PendingDislikeReasons.takeNext(), isNull);
  });

  test('the store is bounded and ignores bad ids', () async {
    for (var i = 1; i <= 9; i++) {
      await PendingDislikeReasons.add(i);
    }
    await PendingDislikeReasons.add(0);
    await PendingDislikeReasons.add(-4);
    expect(await PendingDislikeReasons.load(), [5, 6, 7, 8, 9]);
  });

  test('the tray handler remembers a dislike, and the chat page asks the reason', () {
    final bg = File('lib/core/notifications/background_notification_action_handler.dart')
        .readAsStringSync();
    expect(bg.contains("action == 'dislike'"), isTrue);
    expect(bg.contains('PendingDislikeReasons.add(id)'), isTrue);
    final page = File('lib/features/gate3_interactive/presentation/pages/gate3_interactive_page.dart')
        .readAsStringSync();
    expect(page.contains('_askPendingDislikeReason'), isTrue);
    expect(page.contains('showDislikeReasonSheet('), isTrue);
    expect(page.contains('sendDislikeReason(id, picked)'), isTrue);
    final inbox = File('lib/features/notifications/presentation/pages/notification_inbox_page.dart')
        .readAsStringSync();
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
