import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/theme/app_theme.dart';
import 'package:sedi_app/features/auth_otp/presentation/a2_layout.dart';
import 'package:sedi_app/features/auth_otp/presentation/a2_phone_e164.dart';
import 'package:sedi_app/features/auth_otp/presentation/gate2_otp_input.dart';
import 'package:sedi_app/features/auth_otp/presentation/gate2_widgets.dart';
import 'package:sedi_app/features/auth_otp/presentation/otp_login_localization.dart';
import 'package:sedi_app/features/intro/presentation/pages/intro_page.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  group('F1 Android system splash', () {
    test('launch backgrounds use A1 night sky and no launcher icon', () {
      for (final path in [
        'android/app/src/main/res/drawable/launch_background.xml',
        'android/app/src/main/res/drawable-v21/launch_background.xml',
      ]) {
        final src = _read(path);
        expect(src.contains('@color/a1_launch_background'), isTrue);
        expect(src.contains('@android:color/white'), isFalse);
        expect(src.contains('ic_launcher'), isFalse);
        expect(src.contains('launch_image'), isFalse);
      }

      final colors = _read('android/app/src/main/res/values/colors.xml');
      expect(colors.contains('a1_launch_background'), isTrue);
      expect(colors.contains('#0A0E14'), isTrue);
      expect(AppTheme.introNightSky, const Color(0xFF0A0E14));

      expect(
        File('android/app/src/main/res/drawable/splash_no_brand.xml').existsSync(),
        isTrue,
      );
      final icon = _read('android/app/src/main/res/drawable/splash_no_brand.xml');
      expect(icon.contains('#00000000'), isTrue);
      expect(icon.contains('ic_launcher'), isFalse);
    });

    test('Android 12+ splash theme is icon-free and A1-colored', () {
      for (final path in [
        'android/app/src/main/res/values-v31/styles.xml',
        'android/app/src/main/res/values-night-v31/styles.xml',
      ]) {
        final src = _read(path);
        expect(src.contains('windowSplashScreenBackground'), isTrue);
        expect(src.contains('@color/a1_launch_background'), isTrue);
        expect(src.contains('@drawable/splash_no_brand'), isTrue);
        expect(src.contains('ic_launcher'), isFalse);
      }
    });
  });

  group('F2 A1 status text', () {
    test('intro keeps fail-safe retry and hides diagnostic copy', () {
      final src = _read(
        'lib/features/intro/presentation/pages/intro_page.dart',
      );
      expect(src.contains('while (session.stayOnStartup)'), isTrue);
      expect(src.contains('kReconnectRetryDelay'), isTrue);
      expect(src.contains('resolveColdStart()'), isTrue);
      expect(src.contains('Reconnecting'), isFalse);
      expect(src.contains('temporarily unreachable'), isFalse);
      expect(src.contains('AuthService.clearUserData'), isFalse);
      expect(IntroPage.kIntroDuration, const Duration(milliseconds: 3000));
      expect(IntroPage.kMotionKeyframes, const [
        (0.00, 0.79, 0.05),
        (0.50, 0.52, 0.24),
        (1.00, 0.27, 0.52),
      ]);
    });
  });

  group('F3 OTP slot edit', () {
    testWidgets('every slot is tappable and does not truncate', (tester) async {
      final controller = TextEditingController(text: '123456');
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Gate2OtpInput(
              controller: controller,
              focusNode: focusNode,
            ),
          ),
        ),
      );
      await tester.pump();

      for (var i = 0; i < OtpInputHelper.codeLength; i++) {
        await tester.tap(find.byKey(ValueKey('a2-otp-slot-$i')));
        await tester.pump();
        expect(controller.text, '123456');
        expect(OtpInputHelper.activeSlotFromSelection(
          controller.text,
          controller.selection,
        ), i);
      }
      expect(find.byType(OtpSlotCaret), findsOneWidget);
    });
  });

  group('F4 A2 responsive visual system', () {
    test('shared compact / primary metrics are centralized', () {
      expect(A2Layout.compactControlMax, 300);
      expect(A2Layout.primaryCtaMax, 360);
      expect(A2Layout.readableContentMax, 360);
      expect(A2Layout.primaryCtaHeight, 52);
      expect(A2Layout.primaryCtaFontSize, 18);
      expect(A2Layout.controlFontSize, 16);
      expect(AppTheme.a2PageBackground, const Color(0xFFFFFFFF));
      expect(AppTheme.a2CompactControlMax, A2Layout.compactControlMax);
      expect(AppTheme.a2PrimaryCtaMax, A2Layout.primaryCtaMax);

      final widgets = _read(
        'lib/features/auth_otp/presentation/gate2_widgets.dart',
      );
      expect(widgets.contains('A2Layout.compactControlMax'), isTrue);
      expect(widgets.contains('A2Layout.primaryCtaMax'), isTrue);
      expect(widgets.contains('A2Layout.primaryCtaHeight'), isTrue);
      expect(widgets.contains('A2Layout.primaryCtaFontSize'), isTrue);

      final page = _read(
        'lib/features/auth_otp/presentation/pages/otp_login_page.dart',
      );
      expect(page.contains('AppTheme.a2PageBackground'), isTrue);
    });

    testWidgets('primary CTA uses shared height/font and stays within max width',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: AppTheme.a2PageBackground,
            body: Center(
              child: SizedBox(
                width: 420,
                child: Gate2Widgets.primaryButton(
                  label: 'Confirm',
                  enabled: true,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final label = tester.widget<Text>(find.text('Confirm'));
      expect(label.style?.fontSize, A2Layout.primaryCtaFontSize);
      final box = tester.getSize(find.byType(ElevatedButton));
      expect(box.height, A2Layout.primaryCtaHeight);
      expect(box.width, lessThanOrEqualTo(A2Layout.primaryCtaMax));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('language buttons stay within compact max on a wide canvas',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 420,
                child: Gate2Widgets.languageButton(
                  label: 'English',
                  selected: true,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final size = tester.getSize(find.text('English'));
      expect(size.width, lessThanOrEqualTo(A2Layout.compactControlMax));
    });

    testWidgets('narrow width does not overflow OTP or CTA', (tester) async {
      final controller = TextEditingController(text: '123456');
      final focus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(280, 640)),
            child: Scaffold(
              backgroundColor: AppTheme.a2PageBackground,
              body: Center(
                child: SizedBox(
                  width: 248,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Gate2Widgets.otpSection(
                        l10n: const OtpLoginLocalization('en'),
                        controller: controller,
                        focusNode: focus,
                        active: true,
                        showTitle: false,
                      ),
                      Gate2Widgets.primaryButton(
                        label: 'Confirm',
                        enabled: true,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('fullWidth true stays bounded; false is compact and centered',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Gate2Widgets.primaryButton(
                      label: 'Confirm',
                      enabled: true,
                      onPressed: () {},
                    ),
                    Gate2Widgets.primaryButton(
                      label: 'Send',
                      enabled: true,
                      fullWidth: false,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final fullFinder = find.widgetWithText(ElevatedButton, 'Confirm');
      final compactFinder = find.widgetWithText(ElevatedButton, 'Send');
      final fullBox = tester.getSize(fullFinder);
      final compactBox = tester.getSize(compactFinder);
      expect(fullBox.height, A2Layout.primaryCtaHeight);
      expect(compactBox.height, A2Layout.primaryCtaHeight);
      expect(fullBox.width, lessThanOrEqualTo(A2Layout.primaryCtaMax));
      expect(compactBox.width, lessThan(fullBox.width));
      expect(compactBox.width, lessThan(A2Layout.primaryCtaMax));

      final compactCenter = tester.getCenter(compactFinder);
      final columnCenter = tester.getCenter(find.byType(Column));
      expect((compactCenter.dx - columnCenter.dx).abs(), lessThan(1.0));
    });

    testWidgets('FA/AR page RTL keeps +98 phone digits LTR', (tester) async {
      final controller = TextEditingController(text: '9121234567');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Center(
                child: Gate2Widgets.phoneField(
                  controller: controller,
                  hint: 'Mobile',
                  dialCode: A2PhoneE164.defaultDialCode,
                  onDialCodeChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('+98'), findsOneWidget);
      final dial = tester.widget<Text>(find.text('+98'));
      expect(dial.textDirection, TextDirection.ltr);
      expect(dial.data, '+98');

      final ltrAncestors = find.ancestor(
        of: find.text('+98'),
        matching: find.byWidgetPredicate(
          (w) => w is Directionality && w.textDirection == TextDirection.ltr,
        ),
      );
      expect(ltrAncestors, findsWidgets);

      final fieldFinder = find.byType(TextFormField);
      expect(fieldFinder, findsOneWidget);
      final editable = tester.widget<EditableText>(
        find.descendant(
          of: fieldFinder,
          matching: find.byType(EditableText),
        ),
      );
      expect(editable.textDirection, TextDirection.ltr);
    });
  });
}
