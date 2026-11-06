import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/notifications/background_notification_action_handler.dart';
import 'package:sedi_tray/sedi_tray.dart';

String _read(String path) => File(path).readAsStringSync();

/// R-073 (2F, native tray package): the grown notification is drawn by a native plugin (custom views, five buttons), the
/// answer closes it AT ONCE and Dart runs behind it. The native code is compiled and packaged by the APK build; here the
/// Dart seam (fail-open on every host) and the contracts of the native sources are guarded.
void main() {
  group('the Dart seam is fail-open', () {
    test('on a host that is not Android every call is a no-op', () async {
      expect(SediTray.supported, isFalse);
      expect(
        await SediTray.showGrown(
          id: 1,
          rtl: true,
          title: 'سلام',
          body: 'متن',
          question: 'چرا فعلاً نه؟',
          talkLabel: 'صحبت با صدی',
          notNowLabel: 'فعلاً نه',
          answers: const [SediTrayAnswer(id: 'busy_now', label: 'الان درگیرم')],
          channelId: 'engagement',
          payload: '{}',
          answerPayload: '{}',
        ),
        isFalse,
      );
      expect(await SediTray.registerBackground(1), isFalse);
      expect(await SediTray.drainPending(), isEmpty);
      expect(await SediTray.takeLaunch(), isNull);
    });

    test('an answer is sent as {id, label}', () {
      expect(const SediTrayAnswer(id: 'rest_time', label: 'در استراحتم').toMap(), {'id': 'rest_time', 'label': 'در استراحتم'});
    });
  });

  group('the app uses the native tray and keeps the standard one as the fallback', () {
    test('the reason prompt tries the native tray FIRST and only then builds the standard notification', () {
      final src = _read('lib/core/notifications/background_notification_action_handler.dart');
      final native = src.indexOf('if (await _showNativeGrown(');
      expect(native, greaterThan(0));
      expect(native, lessThan(src.indexOf('final plugin = FlutterLocalNotificationsPlugin();', native)));
      expect(src.contains('return await SediTray.showGrownMap('), isTrue);
      final args = _read('lib/core/notifications/sedi_tray_args.dart');
      expect(args.contains("SediCopy.t('tray.action.open_chat', lang)"), isTrue);
      expect(args.contains("SediCopy.t('tray.action.dislike', lang)"), isTrue);
      expect(args.contains("SediCopy.t('tray.reason.\$r', lang)"), isTrue);
    });

    test('the app registers the background entry at start and picks up kept answers and the «talk» tap', () {
      final boot = _read('lib/core/notifications/notification_bootstrap.dart');
      expect(boot.contains('await SediTrayNativeBridge.registerBackground();'), isTrue);
      expect(boot.contains('SediTrayNativeBridge.pickUp(openChat: _handleNotificationResponse)'), isTrue);
      final bridge = _read('lib/core/notifications/sedi_tray_native.dart');
      expect(bridge.contains("@pragma('vm:entry-point')"), isTrue);
      expect(bridge.contains('Future<void> sediTrayBackgroundEntry()'), isTrue);
      expect(bridge.contains('BackgroundNotificationActionHandler.handle('), isTrue);
      expect(bridge.contains("invokeMethod<void>('ready')"), isTrue);
    });

    test('the pubspec depends on the local plugin', () {
      final pub = _read('pubspec.yaml');
      expect(pub.contains('sedi_tray:'), isTrue);
      expect(pub.contains('path: packages/sedi_tray'), isTrue);
    });
  });

  group('the standard notification (the fallback, and the whole tray below Android 12)', () {
    test('the notification text comes first, then a blank line, then the bold coloured question and its hint', () {
      final html = BackgroundNotificationActionHandler.promptHtml(
        originalBody: 'جواد جان، امروز چطوری؟',
        question: 'چرا فعلاً نه؟',
        hint: 'با یک ضربه جواب بده.',
      );
      expect(html.startsWith('جواد جان، امروز چطوری؟<br><br>'), isTrue);
      expect(html.contains('<b><font color="#7F9E32">چرا فعلاً نه؟</font></b><br>با یک ضربه جواب بده.'), isTrue);
    });

    test('without an original text only the heading and the hint are shown', () {
      final html = BackgroundNotificationActionHandler.promptHtml(originalBody: '  ', question: 'Why not now?', hint: 'Tap one.');
      expect(html, '<b><font color="#7F9E32">Why not now?</font></b><br>Tap one.');
    });

    test('server text can never inject markup, and line breaks are kept', () {
      final html = BackgroundNotificationActionHandler.promptHtml(
        originalBody: 'a <b>x</b> & y\nnext',
        question: 'q',
        hint: 'h',
      );
      expect(html.contains('a &lt;b&gt;x&lt;/b&gt; &amp; y<br>next'), isTrue);
      expect(html.contains('<b>x</b>'), isFalse);
    });
  });

  group('the native tray is drawn only where it is safe', () {
    test('only from Android 12 (API 31); below it the standard notification is shown', () {
      final src = _read('packages/sedi_tray/android/src/main/kotlin/com/sedi/sedi_tray/GrownNotification.kt');
      expect(src.contains('const val MIN_SDK = 31'), isTrue);
      expect(src.contains('if (Build.VERSION.SDK_INT < MIN_SDK) return false'), isTrue);
    });

    test('the expanded layout is kept compact (the custom expanded view is height-limited)', () {
      final xml = _read('packages/sedi_tray/android/src/main/res/layout/sedi_tray_grown_rtl.xml');
      expect(xml.contains('android:id="@+id/tray_body"'), isTrue);
      expect(RegExp(r'android:layout_height="44dp"').hasMatch(xml), isFalse);
      expect(RegExp(r'android:maxLines="2"').allMatches(xml).length, greaterThanOrEqualTo(1));
    });
  });

  group('the native sources keep the promised behaviour', () {
    const kt = 'packages/sedi_tray/android/src/main/kotlin/com/sedi/sedi_tray';

    test('the answer closes the notification BEFORE anything else, keeps the answer, then runs Dart behind it', () {
      final src = _read('$kt/SediTrayActionReceiver.kt');
      final cancel = src.indexOf('NotificationManagerCompat.from(context).cancel(id)');
      final keep = src.indexOf('TrayPrefs.addPending(context, id, answer, payload)');
      final run = src.indexOf('BackgroundRunner.run(context, id, answer, payload)');
      expect(cancel, greaterThan(0));
      expect(cancel, lessThan(keep));
      expect(keep, lessThan(run));
      expect(src.contains('goAsync()'), isTrue);
    });

    test('the runner is fail-open: a timeout or an error leaves the answer for the next start', () {
      final src = _read('$kt/BackgroundRunner.kt');
      expect(src.contains('TIMEOUT_MS'), isTrue);
      expect(src.contains('if (delivered) TrayPrefs.removePending(app, id, answer)'), isTrue);
      expect(src.contains('engine?.destroy()'), isTrue);
    });

    test('the grown notification holds the five buttons, its own title and text, the question and the sphere', () {
      final src = _read('$kt/GrownNotification.kt');
      for (final id in ['tray_title', 'tray_body', 'tray_btn_talk', 'tray_btn_notnow', 'tray_question', 'tray_sphere']) {
        expect(src.contains('R.id.$id'), isTrue, reason: id);
      }
      expect(src.contains('R.id.tray_ans_0, R.id.tray_ans_1, R.id.tray_ans_2'), isTrue);
      expect(src.contains('DecoratedCustomViewStyle'), isTrue);
      expect(src.contains('setTimeoutAfter(TIMEOUT_MS)'), isTrue);
    });

    test('every layout exists in both directions and the receiver is declared', () {
      const res = 'packages/sedi_tray/android/src/main/res';
      for (final name in ['sedi_tray_grown_rtl', 'sedi_tray_grown_ltr', 'sedi_tray_collapsed_rtl', 'sedi_tray_collapsed_ltr']) {
        final xml = _read('$res/layout/$name.xml');
        expect(xml.contains(name.endsWith('rtl') ? 'layoutDirection="rtl"' : 'layoutDirection="ltr"'), isTrue, reason: name);
      }
      for (final id in ['tray_ans_0', 'tray_ans_1', 'tray_ans_2', 'tray_btn_talk', 'tray_btn_notnow', 'tray_sphere']) {
        expect(_read('$res/layout/sedi_tray_grown_rtl.xml').contains('@+id/$id'), isTrue, reason: id);
      }
      final manifest = _read('packages/sedi_tray/android/src/main/AndroidManifest.xml');
      expect(manifest.contains('com.sedi.sedi_tray.SediTrayActionReceiver'), isTrue);
      expect(manifest.contains('android:exported="false"'), isTrue);
      expect(_read('packages/sedi_tray/android/build.gradle').contains('namespace = "com.sedi.sedi_tray"'), isTrue);
    });

    test('the plugin keeps the tap «talk with Sedi» for Dart and closes the notification', () {
      final src = _read('$kt/SediTrayPlugin.kt');
      expect(src.contains('TrayPrefs.setLaunch(ctx, id, payload)'), isTrue);
      expect(src.contains('NotificationManagerCompat.from(ctx).cancel(id)'), isTrue);
    });
  });
}
