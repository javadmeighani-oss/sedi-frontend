import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/notifications/sedi_tray_args.dart';
import 'package:sedi_tray/sedi_tray.dart';

String _read(String path) => File(path).readAsStringSync();

const String _kt = 'packages/sedi_tray/android/src/main/kotlin/com/sedi/sedi_tray';

/// R-073 (no wait): a notification with «talk» + «not now» is drawn natively on ARRIVAL, so the first touch of «not now» grows
/// it at once (no Flutter engine on the tap). Dart seam is fail-open; native contracts are guarded; shared args are exact.
void main() {
  group('arrival seam is fail-open', () {
    test('on a non-Android host showArrival and showGrownMap return false', () async {
      expect(
        await SediTray.showArrival(
          id: 7,
          title: 't',
          body: 'b',
          channelId: 'engagement',
          talkLabel: 'صحبت با صدی',
          notNowLabel: 'فعلاً نه',
          payload: '{}',
          grown: const {},
        ),
        isFalse,
      );
      expect(await SediTray.showGrownMap(const {}), isFalse);
    });
  });

  group('shared grown arguments', () {
    test('the three reasons, own title and body, labels and payloads are carried', () {
      final a = buildGrownArgs(
        id: 5,
        lang: 'fa',
        title: 'عنوان',
        body: 'متن <اصلی> & بیشتر',
        channelId: 'engagement',
        talkPayload: '{"notification_id":"5"}',
        answerPayload: '{"notification_id":"5","reason_prompt":true}',
        talkLabel: 'صحبت با صدی',
        notNowLabel: 'فعلاً نه',
      );
      expect(a['id'], 5);
      expect(a['rtl'], isTrue);
      expect(a['title'], 'عنوان');
      expect(a['talkLabel'], 'صحبت با صدی');
      expect(a['notNowLabel'], 'فعلاً نه');
      expect((a['answers'] as List).map((e) => (e as Map)['id']).toList(), ['busy_now', 'rest_time', 'not_in_mood']);
      final html = a['html'] as String;
      expect(html, contains('متن &lt;اصلی&gt; &amp; بیشتر'));
      expect(html, isNot(contains('<اصلی>')));
      expect(html, contains('<b><font color="#7F9E32">'));
    });

    test('English is left-to-right and empty labels fall back to the catalog', () {
      final a = buildGrownArgs(
        id: 1,
        lang: 'en',
        title: '',
        body: '',
        channelId: 'engagement',
        talkPayload: '{}',
        answerPayload: '{}',
      );
      expect(a['rtl'], isFalse);
      expect((a['talkLabel'] as String).isNotEmpty, isTrue);
      expect((a['notNowLabel'] as String).isNotEmpty, isTrue);
      expect((a['title'] as String).isNotEmpty, isTrue);
    });

    test('a locale tag decides the direction by its language (en-US is left-to-right)', () {
      Map<String, Object?> a(String lang) => buildGrownArgs(
            id: 1,
            lang: lang,
            title: 't',
            body: 'b',
            channelId: 'engagement',
            talkPayload: '{}',
            answerPayload: '{}',
          );
      expect(a('en-US')['rtl'], isFalse);
      expect(a('EN')['rtl'], isFalse);
      expect(a('fa')['rtl'], isTrue);
      expect(a('fa-IR')['rtl'], isTrue);
      expect(a('ar-SA')['rtl'], isTrue);
    });

    test('the dislike marker is not one of the reasons', () {
      expect(kTrayReasons.contains(kTrayDislikeAnswer), isFalse);
      expect(kTrayDislikeAnswer, '__dislike__');
    });
  });

  group('native and Dart contracts', () {
    test('the arrival grows the notification before anything else, then records behind it', () {
      final r = _read('$_kt/SediTrayActionReceiver.kt');
      final grow = r.indexOf('presentFromJson');
      final pend = r.indexOf('addPending(context, id, GrownNotification.ANSWER_DISLIKE');
      final run = r.indexOf('BackgroundRunner.run(context, id, GrownNotification.ANSWER_DISLIKE');
      expect(grow, greaterThan(-1));
      expect(pend, greaterThan(grow));
      expect(run, greaterThan(pend));
    });

    test('custom view only from API 31 with the standard styled notification as fallback', () {
      final g = _read('$_kt/GrownNotification.kt');
      expect(g, contains('MIN_SDK = 31'));
      expect(g, contains('show(context, args) || StandardGrown.show(context, args)'));
      expect(File('$_kt/StandardGrown.kt').existsSync(), isTrue);
    });

    test('the renderer hands only talk+not-now notifications (no plan buttons) to the native tray, fail-open', () {
      final l = _read('lib/core/notifications/local_notifications_service.dart');
      expect(l, contains("!ids.contains('dislike') || !ids.contains('open_chat')"));
      expect(l, contains('planFollowUpActions.contains'));
      expect(l, contains("if (ids.contains('like')) return false;"));
      expect(l, contains('SediTray.showArrival'));
    });

    test('the bridge records the native dislike through the same handler', () {
      final n = _read('lib/core/notifications/sedi_tray_native.dart');
      expect(RegExp('kTrayDislikeAnswer').allMatches(n).length, greaterThanOrEqualTo(2));
      expect(n, contains('acknowledgeNativeDislike'));
    });

    test('the plugin registers the arrival method', () {
      final p = _read('$_kt/SediTrayPlugin.kt');
      expect(p, contains('"showArrival"'));
      expect(p, contains('ArrivalNotification.show'));
    });
  });

  test('no native tray notification auto-cancels: an action tap must not dismiss the notification that «not now» is growing', () {
    for (final f in ['ArrivalNotification.kt', 'GrownNotification.kt', 'StandardGrown.kt']) {
      final src = _read('$_kt/$f');
      expect(src.contains('.setAutoCancel(true)'), isFalse, reason: f);
      expect(src.contains('.setAutoCancel(false)'), isTrue, reason: f);
    }
    // the talk tap still closes the notification explicitly (plugin capture) and every answer cancels itself in the receiver
    expect(_read('$_kt/SediTrayPlugin.kt').contains('NotificationManagerCompat.from(ctx).cancel(id)'), isTrue);
    expect(_read('$_kt/SediTrayActionReceiver.kt').contains('NotificationManagerCompat.from(context).cancel(id)'), isTrue);
  });
}
