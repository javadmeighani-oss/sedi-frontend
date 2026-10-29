import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/data/models/notification_feedback.dart' show kFeedbackReasonValues;
import 'package:sedi_app/features/devices/presentation/devices_l10n.dart';
import 'package:sedi_app/features/notifications/presentation/notification_inbox_l10n.dart';

String _read(String path) => File(path).readAsStringSync();

/// Pilot V1 screens 8-9 + R-039 (Javad 2026-10-29): glass Gadgets and Notifications with the Sedi sphere on the start
/// side of the title; the tray has no Like; Dislike grows the SAME notification and asks why (busy / rest time / no mood).
void main() {
  final devices = _read('lib/features/devices/presentation/pages/devices_page.dart');
  final inbox = _read('lib/features/notifications/presentation/pages/notification_inbox_page.dart');
  final bg = _read('lib/core/notifications/background_notification_action_handler.dart');
  final local = _read('lib/core/notifications/local_notifications_service.dart');

  test('both pages carry the Sedi sphere before the title (R-035) on the soft pistachio scene', () {
    for (final src in [devices, inbox]) {
      expect(src.indexOf('const SediHologramOrb('), lessThan(src.indexOf(RegExp(r'Text\(\s*l10n\.title,'))));
      expect(src.contains('SediSceneBackdrop()'), isTrue);
      expect(src.contains('SediGlass.'), isTrue);
    }
  });

  test('the gadgets page speaks of Sedi\'s own specialised gadgets, with no "after connecting" panel', () {
    expect(devices.contains('l10n.specialTitle'), isTrue);
    expect(devices.contains('l10n.specialBody'), isTrue);
    expect(devices.contains('_WatchPainter'), isTrue);
    for (final lang in ['fa', 'ar', 'en']) {
      final l = DevicesL10n(lang);
      expect(l.specialTitle.trim(), isNotEmpty);
      expect(l.specialBody.contains('سدی'), isFalse);
      expect(l.specialBody.length, greaterThan(40));
    }
    expect(DevicesL10n('fa').specialTitle, 'گجت‌های تخصصی صدی');
  });

  test('inbox cards are glass with justified text and an unread dot', () {
    expect(inbox.contains('SediGlass.card(BorderRadius.circular(24)'), isTrue);
    expect(inbox.contains('textAlign: TextAlign.justify'), isTrue);
    expect(inbox.contains('keyedLogo: false'), isTrue);
  });

  test('the tray has no Like; Dislike keeps the notification and grows it in place (R-039)', () {
    expect(local.contains("const ['open_chat', 'dislike']"), isTrue);
    expect(local.contains("cancelNotification: id != 'dislike' && id != 'plan_not_done'"), isTrue);
    expect(bg.contains('final asksWhy = action == \'dislike\' || action == planNotDoneAction;'), isTrue);
    expect(bg.contains('BigTextStyleInformation('), isTrue);
    expect(BackgroundNotificationActionHandlerReasons.promptReasons, ['busy_now', 'rest_time', 'not_in_mood']);
  });

  test('the reasons exist in every language and in the inbox sheet', () {
    for (final r in ['busy_now', 'rest_time', 'not_in_mood']) {
      expect(kFeedbackReasonValues.contains(r), isTrue, reason: r);
      for (final lang in ['fa', 'ar', 'en']) {
        final label = NotificationInboxL10n(lang).dislikeReasonLabel(r);
        expect(label.trim(), isNotEmpty, reason: '$lang $r');
      }
    }
    expect(NotificationInboxL10n('fa').dislikeReasonLabel('busy_now'), 'الان درگیرم');
    expect(NotificationInboxL10n('fa').dislikeReasonLabel('rest_time'), 'وقت استراحتمه');
    expect(NotificationInboxL10n('fa').dislikeReasonLabel('not_in_mood'), 'حوصله ندارم');
  });
}

/// The handler class keeps its constants private to the isolate; the list is read from the source of truth.
class BackgroundNotificationActionHandlerReasons {
  static List<String> get promptReasons {
    final src = File('lib/core/notifications/background_notification_action_handler.dart').readAsStringSync();
    final m = RegExp(r"promptReasons = <String>\[([^\]]*)\]").firstMatch(src)!;
    return RegExp(r"'([a-z_]+)'").allMatches(m.group(1)!).map((e) => e.group(1)!).toList();
  }
}
