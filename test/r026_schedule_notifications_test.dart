import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/data/dto/chat/chat_send_request.dart';
import 'package:sedi_app/features/lifestyle/presentation/lifestyle_l10n.dart';
import 'package:sedi_app/features/lifestyle/presentation/widgets/schedule_reminder_sheets.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('R-026 chat request carries the device timezone (streaming path too)',
      () {
    final json = const ChatSendRequest(
      message: 'فردا ساعت ۱۰ یادم بنداز',
      timezone: 'Asia/Tehran',
    ).toJson();
    expect(json['timezone'], 'Asia/Tehran');
    expect(
        const ChatSendRequest(message: 'hi').toJson().containsKey('timezone'),
        isFalse);
    final client = _read('lib/services/chat/chat_stream_client.dart');
    expect(client.contains('FlutterTimezone.getLocalTimezone'), isTrue);
    expect(client.contains('timezone: deviceTimezone'), isTrue);
  });

  test(
      'R-026 My Schedule: notification settings, add reminder, delete, "from chat"',
      () {
    final page = _read(
      'lib/features/lifestyle/presentation/pages/lifestyle_schedule_page.dart',
    );
    expect(page.contains('ScheduleNotificationSettingsCard'), isTrue);
    expect(page.contains('ScheduleAddReminderSheet'), isTrue);
    expect(page.contains('createReminder'), isTrue);
    expect(page.contains('deleteEvent'), isTrue);
    expect(page.contains("e.source == 'conversation'"), isTrue);
    expect(page.contains('appointmentOffWarning'), isTrue);
    final card = _read(
      'lib/features/lifestyle/presentation/widgets/schedule_notification_settings_card.dart',
    );
    expect(card.contains('NotificationPrefsRepository'), isTrue);
    expect(card.contains('quietEnabled'), isTrue);
    final repo =
        _read('lib/data/repositories/notification_prefs_repository.dart');
    expect(repo.contains('Future<NotificationPrefsView?> fetch('), isTrue);
    expect(repo.contains("'enabled': quietEnabled ?? true"), isTrue);
  });

  test('R-026 every new string exists in fa / ar / en', () {
    for (final lang in ['fa', 'ar', 'en']) {
      final l = LifestyleL10n(lang);
      for (final s in [
        l.scheduleHeroTitle,
        l.scheduleHeroBody,
        l.addReminder,
        l.reminderWhat,
        l.reminderDate,
        l.reminderTime,
        l.reminderWhen,
        l.save,
        l.cancel,
        l.deleteItem,
        l.fromChat,
        l.pickFutureTime,
        l.reminderNeedsTitle,
        l.saveFailed,
        l.notifSettingsTitle,
        l.notifSettingsSubtitle,
        l.chCompanion,
        l.chAppointment,
        l.chMedication,
        l.chSystem,
        l.chHealthAlert,
        l.quietHours,
        l.quietHoursHint,
        l.quietFrom,
        l.quietTo,
        l.engagementTitle,
        l.engagementLow,
        l.engagementNormal,
        l.engagementHigh,
        l.appointmentOffWarning,
        l.settingsLoadFailed,
      ]) {
        expect(s.trim(), isNotEmpty, reason: lang);
      }
    }
    expect(LifestyleL10n('fa').eventTypeLabel('doctor_visit'), 'نوبت دکتر');
    expect(LifestyleL10n('en').eventTypeLabel('other'), isNull);
    expect(LifestyleL10n('fa').scheduleHeroTitle.contains('سدی'),
        isFalse); // brand is «صدی»
  });

  testWidgets('add-reminder sheet asks for a title, then for a future time',
      (tester) async {
    NewReminderInput? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showModalBottomSheet<NewReminderInput>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) =>
                      ScheduleAddReminderSheet(l10n: LifestyleL10n('fa')),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ثبت'));
    await tester.pump();
    expect(find.text(LifestyleL10n('fa').reminderNeedsTitle), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'قرص فشار');
    await tester.tap(find.text('ثبت'));
    await tester.pumpAndSettle();
    // The default time is one hour ahead and the default offset is "at event time".
    expect(result, isNotNull);
    expect(result!.title, 'قرص فشار');
    expect(result!.offsetMinutes, 0);
    expect(result!.startsAt.isAfter(DateTime.now()), isTrue);
  });
}
