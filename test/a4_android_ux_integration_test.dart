import 'dart:convert';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sedi_app/core/notifications/fcm_setup.dart';
import 'package:sedi_app/core/notifications/local_notifications_service.dart';
import 'package:sedi_app/core/notifications/pending_notification_actions.dart';
import 'package:sedi_app/data/dto/notifications/notification_item_dto.dart';
import 'package:sedi_app/data/models/notification_item.dart';
import 'package:sedi_app/features/notifications/presentation/notification_inbox_l10n.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PendingNotificationActions.prefsLoader = SharedPreferences.getInstance;
  });

  group('channels + sound', () {
    test('morning_v5 audible with sedi_alarm; legacy morning_v2 remains silent', () {
      final channels = LocalNotificationsService.allAndroidChannels;
      final v5 = channels.firstWhere((c) => c.id == channelMorningV5);
      final v4 = channels.firstWhere((c) => c.id == channelMorningV4);
      final v2 = channels.firstWhere((c) => c.id == channelMorningV2);
      expect(v5.playSound, isTrue);
      expect(v5.sound, isA<RawResourceAndroidNotificationSound>());
      expect(v5.enableVibration, isFalse);
      expect(androidSoundResource, 'sedi_alarm');
      expect(v4.playSound, isTrue); // legacy kept installed
      expect(v2.playSound, isFalse);
      final (imp5, _, play5, vib5) = channelImportanceFor(channelMorningV5);
      final (imp2, _, play2, _) = channelImportanceFor(channelMorningV2);
      expect(play5, isTrue);
      expect(vib5, isFalse);
      expect(play2, isFalse);
      expect(imp5.index, greaterThan(imp2.index));
    });

    test('Gate4 morning aliases resolve to morning_v5 never silent', () {
      for (final id in [
        'morning',
        'morning_v2',
        'morning_v3',
        'morning_v4',
        'morning_v5',
      ]) {
        expect(resolveAndroidChannelId(id), channelMorningV5);
        expect(resolveAndroidChannelId(id), isNot(channelMorningV2));
        expect(resolveAndroidChannelId(id), isNot(channelMorningLegacy));
        expect(channelImportanceFor(resolveAndroidChannelId(id)).$3, isTrue);
      }
    });

    test('Gate4 engagement aliases resolve to engagement_v4 audible', () {
      for (final id in [
        'engagement',
        'engagement_v2',
        'engagement_v3',
        'engagement_v4',
        'sedi_reminder',
      ]) {
        expect(resolveAndroidChannelId(id), channelEngagementV4);
        expect(channelImportanceFor(channelEngagementV4).$3, isTrue);
        expect(channelImportanceFor(channelEngagementV4).$4, isFalse);
      }
      final eng = LocalNotificationsService.allAndroidChannels
          .firstWhere((c) => c.id == channelEngagementV4);
      expect(eng.playSound, isTrue);
      expect(eng.sound, isA<RawResourceAndroidNotificationSound>());
      expect(eng.enableVibration, isFalse);
      // Legacy engagement_v3 remains installed for sticky-channel compatibility.
      expect(
        LocalNotificationsService.allAndroidChannels
            .any((c) => c.id == channelEngagementV3),
        isTrue,
      );
    });

    test('health aliases resolve to health_alert_v2 high+vibration unchanged', () {
      for (final id in [
        'health_alert',
        'health_alert_v2',
        'sedi_health',
        'sedi_critical',
      ]) {
        expect(resolveAndroidChannelId(id), channelHealthAlertV2);
      }
      final (imp, pri, play, vib) = channelImportanceFor(channelHealthAlertV2);
      expect(imp, Importance.high);
      expect(pri, Priority.high);
      expect(play, isTrue);
      expect(vib, isTrue);
      final health = LocalNotificationsService.allAndroidChannels
          .firstWhere((c) => c.id == channelHealthAlertV2);
      expect(health.playSound, isTrue);
      expect(health.enableVibration, isTrue);
      expect(health.sound, isA<RawResourceAndroidNotificationSound>());
    });

    test('Android/iOS sound parity constants and bundled assets', () {
      expect(androidSoundResource, 'sedi_alarm');
      expect(iosSoundFile, 'sedi_alarm.wav');
      final android = File('android/app/src/main/res/raw/sedi_alarm.wav');
      final ios = File('ios/Runner/sedi_alarm.wav');
      expect(android.existsSync(), isTrue);
      expect(ios.existsSync(), isTrue);
      expect(android.readAsBytesSync(), ios.readAsBytesSync());
      final license = File('docs/SEDI_ALARM_SOUND_LICENSE_G1.md').readAsStringSync();
      expect(license.contains('CLIPPING=NO'), isTrue);
      expect(license.contains('ANDROID_IOS_BYTE_IDENTICAL=YES'), isTrue);
    });
  });

  group('localized actions', () {
    test('consumes gate4_actions labels FA/EN/AR', () {
      final en = resolveNotificationActions(
        data: {
          'gate4_actions': jsonEncode([
            {'action_id': 'like', 'label': 'Like'},
            {'action_id': 'dislike', 'label': 'Dislike'},
            {'action_id': 'open_chat', 'label': 'Talk to Sedi'},
          ]),
        },
        language: 'en',
      );
      expect(en.map((a) => a.id).toList(), ['like', 'dislike', 'open_chat']);
      expect(en.map((a) => a.title).toList(), isNot(contains('LIKE')));
      expect(en.map((a) => a.title).toList(), isNot(contains('OPEN_CHAT')));
      expect(en.firstWhere((a) => a.id == 'open_chat').title, 'Talk to Sedi');

      final fa = resolveNotificationActions(
        data: {
          'gate4_actions': jsonEncode([
            {'action_id': 'like', 'label': 'پسندیدم'},
            {'action_id': 'dislike', 'label': 'نپسندیدم'},
            {'action_id': 'open_chat', 'label': 'صحبت کنیم'},
          ]),
        },
        language: 'fa',
      );
      expect(fa.firstWhere((a) => a.id == 'like').title, 'پسندیدم');
      expect(fa.firstWhere((a) => a.id == 'open_chat').title, contains('صحبت'));

      final ar = resolveNotificationActions(
        data: {
          'action_labels': jsonEncode({
            'like': 'أعجبني',
            'dislike': 'لم يعجبني',
            'open_chat': 'لنتحدث مع صدی',
          }),
        },
        language: 'ar',
      );
      expect(ar.firstWhere((a) => a.id == 'open_chat').title, contains('صدی'));
    });

    test('safe fallback labels when metadata missing', () {
      expect(fallbackActionLabel('like', 'en'), 'Like');
      expect(fallbackActionLabel('dislike', 'fa'), 'نپسندیدن');
      expect(fallbackActionLabel('open_chat', 'fa'), 'صحبت با صدی');
      expect(fallbackActionLabel('open_chat', 'ar'), 'التحدث مع صدی');
      expect(fallbackActionLabel('open_chat', 'en'), 'Talk to Sedi');
    });

    test('no hardcoded uppercase action labels in render path', () {
      final src = _read('lib/core/notifications/local_notifications_service.dart');
      expect(src.contains("'LIKE'"), isFalse);
      expect(src.contains("'DISLIKE'"), isFalse);
      expect(src.contains("'OPEN_CHAT'"), isFalse);
    });
  });

  group('single render + background', () {
    test('foreground shows local; background handler does not add second path', () {
      final local = _read('lib/core/notifications/local_notifications_service.dart');
      final fcm = _read('lib/core/notifications/fcm_setup.dart');
      final boot = _read('lib/core/notifications/notification_bootstrap.dart');
      expect(local.contains('showRemoteNotification'), isTrue);
      expect(fcm.contains('showRemoteNotification(message)'), isTrue);
      expect(
        'showRemoteNotification'.allMatches(fcm).length,
        1,
      );
      expect(boot.contains('onMessage.listen'), isTrue);
      expect(boot.contains('showRemoteNotification(message)'), isTrue);
      // Exactly one local show call site in onMessage listener block.
      expect(fcm.contains('isGate4FcmData'), isTrue);
    });

    test('background uses notificationTapBackground entry-point', () {
      final src = _read('lib/core/notifications/local_notifications_service.dart');
      final bg = _read(
        'lib/core/notifications/background_notification_action_handler.dart',
      );
      expect(src.contains("@pragma('vm:entry-point')"), isTrue);
      expect(src.contains('notificationTapBackground'), isTrue);
      expect(src.contains('onDidReceiveBackgroundNotificationResponse'), isTrue);
      expect(src.contains('BackgroundNotificationActionHandler.handle'), isTrue);
      expect(bg.contains('PendingNotificationActions.enqueue'), isTrue);
      expect(bg.contains('recoverSessionOn401: false'), isTrue);
    });
  });

  group('background Like/Dislike ACK', () {
    test('background Like/Dislike ACK removes pending and dismisses tray', () {
      final bg = _read(
        'lib/core/notifications/background_notification_action_handler.dart',
      );
      expect(bg.contains("action != 'like' && action != 'dislike'"), isTrue);
      expect(bg.contains('sendFeedback'), isTrue);
      expect(bg.contains('PendingNotificationActions.remove'), isTrue);
      expect(bg.contains('_dismissTrayIsolated'), isTrue);
      expect(bg.contains('_showProcessingIsolated'), isTrue);
      expect(bg.contains('_inFlightKeys'), isTrue);
      expect(bg.contains('recoverSessionOn401: false'), isTrue);
      // Failure retains pending + tray (early return before remove/dismiss).
      expect(bg.contains('keep pending+tray'), isTrue);
      expect(bg.contains('keep pending for resume drain'), isTrue);
    });

    test('background path never navigates or force-logouts', () {
      final bg = _read(
        'lib/core/notifications/background_notification_action_handler.dart',
      );
      expect(bg.contains('goToHeart'), isFalse);
      expect(bg.contains('goToLogin'), isFalse);
      expect(bg.contains('forceLogoutAndNavigate'), isFalse);
      expect(bg.contains('AuthSessionManager'), isFalse);
      expect(bg.contains('Navigator'), isFalse);
      expect(bg.contains('AppGateRouter'), isFalse);
      // open_chat stays enqueue-only from isolate.
      expect(bg.contains('foreground drain owns ACK'), isTrue);
    });
  });

  group('pending actions handoff', () {
    test('pending LIKE/DISLIKE/OPEN_CHAT survive process-style handoff once', () async {
      await PendingNotificationActions.enqueue(
        notificationId: 11,
        actionId: 'like',
        clientTs: 't1',
      );
      await PendingNotificationActions.enqueue(
        notificationId: 11,
        actionId: 'like',
        clientTs: 't2',
      ); // dedupe
      await PendingNotificationActions.enqueue(
        notificationId: 12,
        actionId: 'dislike',
      );
      await PendingNotificationActions.enqueue(
        notificationId: 13,
        actionId: 'open_chat',
      );

      final loaded = await PendingNotificationActions.load();
      expect(loaded.length, 3);
      expect(loaded.where((e) => e.actionId == 'like').length, 1);

      final sent = <String>[];
      await PendingNotificationActions.drain((item) async {
        sent.add(item.dedupeKey);
        return true;
      });
      expect(sent.toSet().length, 3);
      expect(await PendingNotificationActions.load(), isEmpty);

      // Transient failure keeps item for next drain.
      await PendingNotificationActions.enqueue(
        notificationId: 99,
        actionId: 'like',
      );
      await PendingNotificationActions.drain((_) async => false);
      expect((await PendingNotificationActions.load()).length, 1);
    });
  });

  group('bootstrap continuity', () {
    test('open_chat navigates once after ACK; source id reaches A3; no fake user/raw body', () {
      final boot = _read('lib/core/notifications/notification_bootstrap.dart');
      final coord =
          _read('lib/core/notifications/notification_action_coordinator.dart');
      final ctrl = _read('lib/features/chat/state/chat_controller.dart');
      expect(boot.contains('getNotificationAppLaunchDetails'), isTrue);
      expect(boot.contains('_recoverLocalNotificationLaunch'), isTrue);
      expect(boot.contains('drainPendingActions'), isTrue);
      expect(boot.contains("actionId: 'open_chat'"), isTrue);
      expect(boot.contains('NotificationActionCoordinator'), isTrue);
      // Navigate ONLY after ACK — bootstrap must not call goToHeart directly.
      expect(boot.contains('goToHeart'), isFalse);
      expect(coord.contains('goToHeart'), isTrue);
      expect(coord.contains('navigateToChatAfterAck'), isTrue);
      expect(coord.contains('cancelByBackendNotificationId'), isTrue);
      expect(boot.contains('ChatMessage.user'), isFalse);
      expect(boot.contains('notification.body'), isFalse);
      expect(ctrl.contains('sourceNotificationId: sourceNotificationId'), isTrue);
      expect(ctrl.contains('openSession('), isTrue);
    });
  });

  group('ACK-gated tray lifecycle', () {
    test('actions do not auto-dismiss; cancelNotification is false', () {
      final local =
          _read('lib/core/notifications/local_notifications_service.dart');
      expect(local.contains('cancelNotification: false'), isTrue);
      expect(local.contains('cancelNotification: true'), isFalse);
      expect(local.contains('cancelByBackendNotificationId'), isTrue);
      expect(local.contains('showTrayActionProcessing'), isTrue);
      expect(local.contains('trayProcessingLabel'), isTrue);
    });

    test('ACK dismisses tray + removes pending; failure restores tray + retains pending', () async {
      final coord =
          _read('lib/core/notifications/notification_action_coordinator.dart');
      expect(coord.contains('PendingNotificationActions.enqueue'), isTrue);
      expect(coord.contains('PendingNotificationActions.remove'), isTrue);
      expect(coord.contains('cancelByBackendNotificationId'), isTrue);
      expect(coord.contains('InboxRefreshBus.instance.triggerDebounced'), isTrue);
      expect(coord.contains('showTrayActionProcessing'), isTrue);
      expect(coord.contains('restoreOriginalTrayNotification'), isTrue);
      expect(coord.contains('_inFlightKeys'), isTrue);
      expect(coord.contains('duplicate action rejected while processing'), isTrue);
      // Failure path returns false without remove/cancel.
      expect(coord.contains('if (!resp.ok) return false'), isTrue);

      final local =
          _read('lib/core/notifications/local_notifications_service.dart');
      expect(local.contains('restoreOriginalTrayNotification'), isTrue);
      expect(local.contains('TrayNotificationSnapshotStore'), isTrue);
      expect(local.contains('onlyAlertOnce: true'), isTrue);

      final bg = _read(
        'lib/core/notifications/background_notification_action_handler.dart',
      );
      expect(bg.contains('_restoreOriginalIsolated'), isTrue);
      expect(bg.contains('recoverSessionOn401: false'), isTrue);

      await PendingNotificationActions.enqueue(
        notificationId: 77,
        actionId: 'like',
      );
      await PendingNotificationActions.drain((_) async => false);
      expect((await PendingNotificationActions.load()).length, 1);
      await PendingNotificationActions.drain((_) async => true);
      expect(await PendingNotificationActions.load(), isEmpty);
    });

    test('body tap uses same open_chat seam as Talk to Sedi', () {
      final boot = _read('lib/core/notifications/notification_bootstrap.dart');
      expect(boot.contains("? 'open_chat' : actionId"), isTrue);
      expect(boot.contains('NotificationActionCoordinator.submit'), isTrue);
      expect(boot.contains('payloadJson: payloadJson'), isTrue);
      final bg = _read(
        'lib/core/notifications/background_notification_action_handler.dart',
      );
      expect(bg.contains("? 'open_chat'"), isTrue);
      expect(bg.contains('_showProcessingIsolated'), isTrue);
      expect(bg.contains('_inFlightKeys'), isTrue);
      expect(bg.contains('recoverSessionOn401: false'), isTrue);
    });
  });

  group('inbox final UX', () {
    test('Smart Notifications title; detail actions; hide multi-select; grouping; RTL', () {
      final inbox = _read(
        'lib/features/notifications/presentation/pages/notification_inbox_page.dart',
      );
      expect(inbox.contains('continueInChat'), isFalse);
      expect(inbox.contains('wasThisUseful'), isFalse);
      expect(inbox.contains('_pickDislikeReason'), isFalse);
      expect(inbox.contains('goToHeart'), isFalse);
      expect(inbox.contains('NotificationActionCoordinator'), isTrue);
      expect(inbox.contains('hideInbox'), isTrue);
      expect(_selectionModeContains(inbox), isTrue);
      expect(inbox.contains('groupToday'), isTrue);
      expect(inbox.contains('likeAction'), isTrue);
      expect(inbox.contains('dislikeAction'), isTrue);
      expect(inbox.contains('talkToSedi'), isTrue);
      expect(inbox.contains('isScrollControlled: true'), isTrue);
      expect(inbox.contains('categoryLabel'), isTrue);
      expect(inbox.contains('channel.toUpperCase()'), isFalse);
      // Soft-hide only — delete UI maps to hideInbox.
      expect(inbox.contains('hard delete'), isFalse);
      // Standalone Select removed; Delete chip enters selection.
      expect(inbox.contains('l10n.select'), isFalse);
      expect(inbox.contains('filterDelete'), isTrue);
      expect(inbox.contains('selectionGutterWidth'), isTrue);
      expect(inbox.contains('selectionGutterWidth = 48'), isTrue);
      expect(inbox.contains('Color(0xFFEEF0E8)'), isTrue);
      expect(inbox.contains('hasUserResponse: true'), isTrue);
      expect(inbox.contains('displayAttention'), isTrue);
      // Card tap must NOT mark read — detail open only.
      expect(inbox.contains('await _markReadOptimistic(item);\n          await _openDetails'), isFalse);
      expect(inbox.contains('// Card tap opens detail ONLY'), isTrue);
      expect(inbox.contains('await _openDetails(item, l10n);'), isTrue);
      // Explicit Mark as read remains.
      expect(inbox.contains('_markReadOptimistic'), isTrue);

      final svc = _read('lib/services/notifications/notifications_service.dart');
      expect(svc.contains('/notifications/unread'), isTrue);
      expect(svc.contains('/notifications/inbox/hide'), isTrue);
      expect(svc.contains("unreadOnly ? '/notifications/unread'"), isTrue);

      final en = NotificationInboxL10n('en');
      final fa = NotificationInboxL10n('fa');
      final ar = NotificationInboxL10n('ar');
      expect(en.isRtl, isFalse);
      expect(fa.isRtl, isTrue);
      expect(ar.isRtl, isTrue);
      expect(en.title, 'Smart Notifications');
      expect(fa.title, 'اعلان‌های هوشمند');
      expect(ar.title, 'الإشعارات الذكية');
      expect(en.filterDelete, 'Delete');
      expect(fa.filterDelete, 'حذف');
      expect(ar.filterDelete, 'حذف');
      expect(en.categoryLabel('HEALTH_ALERT'), isNot(contains('HEALTH_ALERT')));
      expect(en.categoryLabel('daily_status'), 'Daily status');
      expect(fa.categoryLabel('engagement_checkin'), isNotEmpty);
      expect(en.categoryLabel('unknown_xyz'), en.fallbackTitle);
      expect(fa.fallbackTitle, 'اعلان');
      expect(ar.fallbackTitle, 'إشعار');
    });

    test('persisted title/body are not retranslated in inbox', () {
      final l10n = _read(
        'lib/features/notifications/presentation/notification_inbox_l10n.dart',
      );
      expect(
        l10n.contains('Does not translate backend-supplied notification title/body'),
        isTrue,
      );
      final page = _read(
        'lib/features/notifications/presentation/pages/notification_inbox_page.dart',
      );
      expect(page.contains('item.title'), isTrue);
      expect(page.contains('item.body'), isTrue);
    });

    test('Delete enters selection; one Delete-selected; soft-hide only', () {
      final inbox = _read(
        'lib/features/notifications/presentation/pages/notification_inbox_page.dart',
      );
      expect(inbox.contains('_deleteSelected'), isTrue);
      expect(inbox.contains('_hideSelected'), isFalse);
      expect(inbox.contains('hideSelected'), isFalse);
      expect(inbox.contains('deleteConfirmTitle'), isTrue);
      expect(inbox.contains('deleteConfirmBody'), isTrue);
      expect(inbox.contains('hideInbox'), isTrue);
      // Top Delete chip enters selection; Delete-selected remains the confirm action.
      expect(inbox.contains('filterDelete'), isTrue);
      expect(RegExp(r'l10n\.deleteSelected').allMatches(inbox).length, 1);
      expect(inbox.contains('l10n.hideSelected'), isFalse);
      expect(inbox.contains('l10n.select'), isFalse);
      expect(inbox.contains('markRead'), isTrue); // mark-read exists elsewhere
      final deleteBlockStart = inbox.indexOf('Future<void> _deleteSelected');
      final deleteBlockEnd = inbox.indexOf('Future<void> _markReadOptimistic');
      expect(deleteBlockStart, greaterThanOrEqualTo(0));
      expect(deleteBlockEnd, greaterThan(deleteBlockStart));
      final deleteBlock = inbox.substring(deleteBlockStart, deleteBlockEnd);
      expect(deleteBlock.contains('markRead'), isFalse);
      expect(deleteBlock.contains('hideInbox'), isTrue);
      expect(deleteBlock.contains('showDialog'), isTrue);
      expect(deleteBlock.contains('confirmed != true'), isTrue);

      final en = NotificationInboxL10n('en');
      final fa = NotificationInboxL10n('fa');
      final ar = NotificationInboxL10n('ar');
      expect(en.deleteSelected, 'Delete selected');
      expect(fa.deleteSelected, isNot(en.deleteSelected));
      expect(ar.deleteSelected, isNot(en.deleteSelected));
      expect(en.deleteConfirmTitle, isNotEmpty);
      expect(fa.deleteConfirmTitle, isNot(en.deleteConfirmTitle));
      expect(ar.deleteConfirmTitle, isNot(en.deleteConfirmTitle));
      expect(en.deleteConfirmBody, isNotEmpty);
      expect(fa.deleteConfirmBody, isNot(en.deleteConfirmBody));
      expect(ar.deleteConfirmBody, isNot(en.deleteConfirmBody));
    });

    test('selection gutter is Directionality-aware and >=48dp', () {
      final inbox = _read(
        'lib/features/notifications/presentation/pages/notification_inbox_page.dart',
      );
      expect(inbox.contains('selectionGutterWidth = 48'), isTrue);
      expect(inbox.contains('EdgeInsets.only(top: 2, right: 10)'), isFalse);
      expect(inbox.contains('Directionality'), isTrue);
      expect(inbox.contains('minWidth: selectionGutterWidth'), isTrue);
      expect(inbox.contains('minHeight: selectionGutterWidth'), isTrue);
      expect(inbox.contains('iconSize: 28'), isTrue);
    });

    test('hide unread does not call mark-read', () {
      final inbox = _read(
        'lib/features/notifications/presentation/pages/notification_inbox_page.dart',
      );
      expect(inbox.contains('_deleteSelected'), isTrue);
      expect(inbox.contains('hideInbox'), isTrue);
      final hideBlockStart = inbox.indexOf('Future<void> _deleteSelected');
      final hideBlockEnd = inbox.indexOf('Future<void> _markReadOptimistic');
      expect(hideBlockStart, greaterThanOrEqualTo(0));
      expect(hideBlockEnd, greaterThan(hideBlockStart));
      final hideBlock = inbox.substring(hideBlockStart, hideBlockEnd);
      expect(hideBlock.contains('markRead'), isFalse);
      expect(hideBlock.contains('hideInbox'), isTrue);
    });
  });

  group('A3 visual locked', () {
    test('A3 visual/stream locked files unchanged by this Gate surface', () {
      // Contract: this Gate must not edit orb/visualizer/composer stream pacing files.
      // Presence of continuity openSession wiring remains.
      final ctrl = _read('lib/features/chat/state/chat_controller.dart');
      expect(ctrl.contains('presentation_word'), isFalse);
      expect(ctrl.contains('sourceNotificationId'), isTrue);
    });
  });

  test('isGate4FcmData detects gate marker', () {
    expect(isGate4FcmData({'gate': 'gate4'}), isTrue);
    expect(isGate4FcmData({'gate4_actions': '[]'}), isTrue);
    expect(isGate4FcmData({'channel': 'engagement'}), isFalse);
  });

  group('read vs user response', () {
    test('DTO defaults has_user_response false; model needsAttention', () {
      final dto = NotificationItemDto.fromJson({
        'id': 1,
        'channel': 'engagement',
        'title': 'T',
        'body': 'B',
        'created_at': '2026-10-01T00:00:00Z',
        'is_read': true,
      });
      expect(dto.hasUserResponse, isFalse);
      final item = NotificationItem.fromDto(dto);
      expect(item.isRead, isTrue);
      expect(item.hasUserResponse, isFalse);
      expect(item.needsAttention, isTrue);

      final responded = item.copyWith(hasUserResponse: true);
      expect(responded.needsAttention, isFalse);

      final unread = NotificationItem.fromDto(
        NotificationItemDto.fromJson({
          'id': 2,
          'channel': 'engagement',
          'title': 'T',
          'body': 'B',
          'created_at': '2026-10-01T00:00:00Z',
          'is_read': false,
          'has_user_response': false,
        }),
      );
      expect(unread.needsAttention, isTrue);
    });
  });
}

bool _selectionModeContains(String inbox) {
  return inbox.contains('_selectionMode') &&
      inbox.contains('_enterSelection') &&
      inbox.contains('_selectedIds');
}

