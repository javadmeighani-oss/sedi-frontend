import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/notifications/background_notification_action_handler.dart';
import 'package:sedi_app/data/dto/lifestyle/plan_settings_dto.dart';
import 'package:sedi_app/features/lifestyle/presentation/plan_coach_l10n.dart';
import 'package:sedi_app/features/lifestyle/presentation/widgets/plan_setup_sheet.dart';

String _read(String path) => File(path).readAsStringSync();

/// Javad 2026-11-01: (1) the "why?" of a notification is a visibly separate block; (2) "Next" in step 1 of 3 must never
/// look dead - the missing allergy answer lights up where it belongs; (3) "Professional" is ONE plan, diet and exercise
/// together, named the same on the meal page and the exercise page.
void main() {
  group('the feedback is a modern conversation inside the same notification', () {
    test('both tray prompts are a Sedi conversation (her sphere as avatar), not a text-art frame', () {
      final bg = _read('lib/core/notifications/background_notification_action_handler.dart');
      expect(RegExp('promptStyle\\(').allMatches(bg).length, 3); // the definition + the two prompts
      expect(RegExp('styleInformation: style').allMatches(bg).length, 2);
      expect(bg.contains('MessagingStyleInformation('), isTrue);
      expect(bg.contains('ByteArrayAndroidIcon('), isTrue);
      expect(bg.contains('androidBrandLargeIconAsset'), isTrue);
      // no block characters / HTML frame any more
      expect(bg.contains('&#9612;'), isFalse);
      expect(bg.contains('htmlFormatBigText: true'), isFalse);
      expect(bg.contains('final expanded = growWithQuestion('), isFalse);
    });

    test('the plain big-text fallback still keeps the original text first and appends the question', () {
      final text = BackgroundNotificationActionHandler.growWithQuestion(
        originalBody: 'امروز چطوری؟',
        question: 'چرا نپسندیدی؟',
        hint: 'یکی رو بزن.',
      );
      expect(text.startsWith('امروز چطوری؟'), isTrue);
      expect(text.contains('چرا نپسندیدی؟'), isTrue);
    });

    test('the large icon and the avatar are the glass sphere with the official wordmark', () {
      final service = _read('lib/core/notifications/local_notifications_service.dart');
      expect(service.contains("'assets/images/sedi_notification_sphere.png'"), isTrue);
      expect(File('assets/images/sedi_notification_sphere.png').existsSync(), isTrue);
    });
  });

  group('Health page carries the Sedi sphere and the glass look', () {
    test('uses the shared scene backdrop, the sphere beside the title and glass cards', () {
      final page = _read('lib/features/lifestyle/presentation/pages/lifestyle_health_page.dart');
      expect(page.contains('SediSceneBackdrop'), isTrue);
      expect(page.contains('_glass('), isTrue);
      expect(page.contains('_PulsePainter'), isTrue);
    });
  });

  group('plan setup: "Next" never looks dead', () {
    test('the missing allergy answer lights up its own block and scrolls to it (no far-away bottom message)', () {
      final sheet = _read('lib/features/lifestyle/presentation/widgets/plan_setup_sheet.dart');
      expect(sheet.contains('void _flagAllergy()'), isTrue);
      expect(sheet.contains('Widget _allergyBlock()'), isTrue);
      expect(sheet.contains('Scrollable.ensureVisible'), isTrue);
      expect(sheet.contains('_notice = _l.allergyNeeded'), isFalse);
      expect(RegExp('_allergyBlock\\(\\)').allMatches(sheet).length, 3); // the definition + the goal step + the simple meal step
    });

    testWidgets('step 1 of 3: Next without the allergy answer stays, says why right under the answer; answering moves on',
        (tester) async {
      tester.view.physicalSize = const Size(900, 1900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final l = PlanCoachL10n('fa');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => showPlanSetupSheet(
                  ctx,
                  l10n: l,
                  nutrition: false,
                  initialSettings: const PlanSettingsDto(),
                  onSubmit: (_) async => PlanSetupOutcome.built,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.modePro));
      await tester.pumpAndSettle();
      expect(find.text(l.stepOf(0)), findsOneWidget);

      await tester.tap(find.text(l.next));
      await tester.pumpAndSettle();
      expect(find.text(l.allergyNeeded), findsOneWidget); // once, inline - not a second line at the bottom
      expect(find.text(l.stepOf(0)), findsOneWidget); // still step 1

      await tester.tap(find.text(l.noAllergy));
      await tester.pumpAndSettle();
      expect(find.text(l.allergyNeeded), findsNothing);
      await tester.tap(find.text(l.next));
      await tester.pumpAndSettle();
      expect(find.text(l.stepOf(1)), findsOneWidget);
    });
  });

  group('"Professional" is one plan: diet and exercise together', () {
    test('the same professional choice on both pages; the simple choice names its own page', () {
      for (final lang in ['fa', 'ar', 'en']) {
        final l = PlanCoachL10n(lang);
        expect(l.modePro.trim(), isNotEmpty, reason: lang);
        expect(l.modeProHint.trim(), isNotEmpty, reason: lang);
        expect(l.modeSimpleFor(true), isNot(l.modeSimpleFor(false)), reason: lang);
        expect(l.openOtherPlan(true), isNot(l.openOtherPlan(false)), reason: lang);
        expect(l.proBuiltOk(true), isNot(l.proBuiltOk(false)), reason: lang);
        for (final s in [l.modePro, l.modeProHint, l.modeSimpleFor(true), l.modeSimpleFor(false), l.proBuiltOk(true), l.openOtherPlan(false)]) {
          expect(s.contains('سدی'), isFalse, reason: lang);
        }
      }
      final fa = PlanCoachL10n('fa');
      expect(fa.modePro, 'حرفه‌ای · رژیم غذایی و ورزش با هم');
      expect(fa.modeSimpleFor(true), 'ساده · برنامه‌ی غذایی');
      expect(fa.modeSimpleFor(false), 'ساده · برنامه‌ی ورزشی');
      expect(fa.modePro.contains('با رژیم غذایی'), isFalse); // the old, meaningless-on-the-meal-page wording
    });

    test('after a professional build the page says both plans exist and opens the other page in one tap', () {
      final view = _read('lib/features/lifestyle/presentation/widgets/lifestyle_weekly_plan_view.dart');
      expect(view.contains('_lastSetupWasPro = input.mode == \'pro\''), isTrue);
      expect(view.contains('coach.proBuiltOk(_isNutrition)'), isTrue);
      expect(view.contains('SnackBarAction('), isTrue);
      expect(view.contains('coach.openOtherPlan(_isNutrition)'), isTrue);
      expect(view.contains('_isNutrition ? LifestyleWeeklyDomain.exercise : LifestyleWeeklyDomain.nutrition'), isTrue);
      // the mode cards use the page-aware texts
      final sheet = _read('lib/features/lifestyle/presentation/widgets/plan_setup_sheet.dart');
      expect(sheet.contains('_l.modeSimpleFor(widget.nutrition)'), isTrue);
      expect(sheet.contains('title: _l.modePro'), isTrue);
    });
  });
}
