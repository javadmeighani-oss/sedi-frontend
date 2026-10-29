import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/gate3_localization.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/gate3_main_icon_button.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/gate3_main_icon_row.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  group('A3 top action row source contract', () {
    test('equal-width actions, no plainIcon column width, icon-local badge', () {
      final row = _read(
        'lib/features/gate3_interactive/presentation/widgets/gate3_main_icon_row.dart',
      );
      final button = _read(
        'lib/features/gate3_interactive/presentation/widgets/gate3_main_icon_button.dart',
      );

      expect('Expanded('.allMatches(row).length, 4);
      expect(row.contains('.reversed'), isFalse);
      expect(row.contains('PositionedDirectional'), isFalse);
      final profileCall = row.indexOf('l10n.profileTitle');
      final lifestyleCall = row.indexOf('l10n.lifestyle');
      final gadgetsCall = row.indexOf('l10n.gadgets');
      final notificationsCall = row.indexOf('l10n.notifications');
      expect(profileCall, greaterThan(0));
      expect(lifestyleCall, greaterThan(profileCall));
      expect(gadgetsCall, greaterThan(lifestyleCall));
      expect(notificationsCall, greaterThan(gadgetsCall));

      expect(button.contains('plainIcon ? 56 : 72'), isFalse);
      expect(button.contains('width: 56'), isFalse);
      expect(button.contains('width: 72'), isFalse);
      // pilot V1 (R-034): the tile is a glass square sized by one constant, still never a fixed 56 / 72 column
      expect(button.contains('width: tileSize'), isTrue);
      expect(button.contains('height: tileSize'), isTrue);
      expect(button.contains('maxLines: 1'), isTrue);
      expect(button.contains('softWrap: false'), isTrue);
      expect(button.contains('BoxFit.scaleDown'), isTrue);
      expect(button.contains('TextOverflow.ellipsis'), isFalse);
      expect(button.contains('PositionedDirectional'), isTrue);
    });

    test('EN/FA/AR action labels remain canonical and complete', () {
      const en = Gate3Localization('en');
      const fa = Gate3Localization('fa');
      const ar = Gate3Localization('ar');
      expect(en.profileTitle, 'Profile');
      expect(en.lifestyle, 'Lifestyle');
      expect(en.gadgets, 'Gadgets');
      expect(en.notifications, 'Notifications');
      expect(fa.profileTitle, 'پروفایل');
      expect(fa.lifestyle, 'سبک زندگی');
      expect(fa.gadgets, 'گجت‌ها');
      expect(fa.notifications, 'اعلان‌ها');
      expect(ar.profileTitle, 'الملف الشخصي');
      expect(ar.lifestyle, 'نمط الحياة');
      expect(ar.gadgets, 'الأجهزة');
      expect(ar.notifications, 'الإشعارات');
    });
  });

  group('A3 top action row equal widths', () {
    Future<void> pumpRow(WidgetTester tester, double width, String lang) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: Gate3MainIconRow(
                  lang: lang,
                  unreadNotificationCount: 3,
                  onLifestyle: () {},
                  onGadgets: () {},
                  onNotifications: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    for (final width in [320.0, 360.0, 412.0]) {
      testWidgets('four equal-width actions at ${width.toInt()}dp',
          (tester) async {
        await pumpRow(tester, width, 'en');
        final boxes = tester
            .widgetList<Gate3MainIconButton>(find.byType(Gate3MainIconButton))
            .toList();
        expect(boxes.length, 4);
        final widths = [
          for (final w in boxes) tester.getSize(find.byWidget(w)).width,
        ];
        expect(widths[0], closeTo(width / 4, 0.6));
        expect(widths[1], closeTo(widths[0], 0.6));
        expect(widths[2], closeTo(widths[0], 0.6));
        expect(widths[3], closeTo(widths[0], 0.6));
        expect(find.text('Notifications'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Notifications stays one complete line in EN/FA/AR',
        (tester) async {
      for (final lang in ['en', 'fa', 'ar']) {
        await pumpRow(tester, 320, lang);
        final l10n = Gate3Localization(lang);
        expect(find.text(l10n.notifications), findsOneWidget);
        expect(find.text(l10n.profileTitle), findsOneWidget);
        expect(find.text(l10n.lifestyle), findsOneWidget);
        expect(find.text(l10n.gadgets), findsOneWidget);
        final label = tester.widget<Text>(find.text(l10n.notifications));
        expect(label.maxLines, 1);
        expect(label.softWrap, isFalse);
        expect(label.overflow, isNot(TextOverflow.ellipsis));
      }
    });
  });
}
