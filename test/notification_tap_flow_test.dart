import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/notifications/background_notification_action_handler.dart';
import 'package:sedi_app/core/notifications/notification_action_coordinator.dart';

String _read(String path) => File(path).readAsStringSync();

/// Phone test 2026-10-30 (tray): (1) after Dislike the question must open INSIDE the same notification - its own title
/// and text stay, the question and the three answers come below them, and at once; (2) "Talk to Sedi" must open the chat
/// even when the feedback request is slow or fails.
void main() {
  group('the question grows inside the same notification', () {
    test('the original text stays and the question is added below it', () {
      final text = BackgroundNotificationActionHandler.growWithQuestion(
        originalBody: 'امروز چطوری؟ دلم می‌خواست یه احوالی ازت بپرسم.',
        question: 'چرا نپسندیدی؟',
        hint: 'یکی رو بزن تا دفعه‌ی بعد توی وقت بهتری برات بفرستم.',
      );
      expect(text.startsWith('امروز چطوری؟'), isTrue);
      expect(text.contains('\n\nچرا نپسندیدی؟\n'), isTrue);
      expect(text.endsWith('بفرستم.'), isTrue);
    });

    test('no stored original: the question alone', () {
      final text = BackgroundNotificationActionHandler.growWithQuestion(
        originalBody: '  ',
        question: 'Why?',
        hint: 'Pick one.',
      );
      expect(text, 'Why?\nPick one.');
    });

    test('both prompts keep the notification\'s own title and body and show first, before the network', () {
      final bg = _read('lib/core/notifications/background_notification_action_handler.dart');
      expect(RegExp(r'TrayNotificationSnapshotStore\.get\(notificationId\)').allMatches(bg).length, 2);
      expect(bg.contains('BigTextStyleInformation(\n              expanded,'), isTrue);
      final handle = bg.substring(bg.indexOf('static Future<void> handle('), bg.indexOf('/// Returns true on ACK'));
      expect(handle.indexOf('_showReasonPrompt('), lessThan(handle.indexOf('_attemptLikeDislikeAck(')));
      expect(handle.indexOf('_showPlanReasonPrompt('), lessThan(handle.indexOf('_attemptLikeDislikeAck(')));
    });
  });

  group('"Talk to Sedi" opens the chat at once', () {
    final now = DateTime.utc(2026, 10, 30, 12, 0, 0);

    test('a tap from a minute ago is fresh; an old queued retry is not', () {
      expect(NotificationActionCoordinator.isFreshTap(now.subtract(const Duration(seconds: 40)).toIso8601String(), now), isTrue);
      expect(NotificationActionCoordinator.isFreshTap(now.subtract(const Duration(minutes: 3)).toIso8601String(), now), isFalse);
      expect(NotificationActionCoordinator.isFreshTap('not a date', now), isFalse);
    });

    test('submit opens the chat before it asks the network anything', () {
      final c = _read('lib/core/notifications/notification_action_coordinator.dart');
      final submit = c.substring(c.indexOf('static Future<bool> submit('), c.indexOf('/// Drain all pending actions'));
      expect(submit.indexOf('openChatNow('), greaterThan(0));
      expect(submit.indexOf('openChatNow('), lessThan(submit.indexOf('hasValidSession()')));
      expect(submit.contains('_ackOne(item, navigateOnOpenChat: false)'), isTrue); // no second navigation after the ACK
    });

    test('a tap that was queued while the app was closed opens the chat before the session check', () {
      final c = _read('lib/core/notifications/notification_action_coordinator.dart');
      final drain = c.substring(c.indexOf('static Future<void> drainPendingActions('), c.indexOf('static Future<bool> _ackOne('));
      expect(drain.indexOf('isFreshTap('), lessThan(drain.indexOf('hasValidSession()')));
    });

    test('openChatNow needs only the local token, waits for the navigator, and counts the id only when it opens', () {
      final c = _read('lib/core/notifications/notification_action_coordinator.dart');
      final open = c.substring(c.indexOf('static Future<void> openChatNow('), c.indexOf('static Future<BuildContext?> _navigatorContext('));
      expect(open.contains('AuthService.hasToken()'), isTrue);
      expect(open.contains('hasValidSession'), isFalse); // no network gate in front of the chat
      expect(open.indexOf('_navigatorContext()'), lessThan(open.indexOf('_openChatNavigatedIds.add(id)')));
      expect(open.contains('goToHeart('), isTrue);
      expect(open.contains('fromNotification: true'), isTrue);
    });

    test('a chat opened from a notification asks for its own opener, never the prefetched plain one', () {
      final ctrl = _read('lib/features/chat/state/chat_controller.dart');
      final guard = ctrl.indexOf('if (sourceNotificationId != null) A3SessionPrefetch.take();');
      expect(guard, greaterThan(0));
      expect(guard, lessThan(ctrl.indexOf('A3SessionPrefetch.take() ?? _openSessionSoft()')));
    });
  });
}
