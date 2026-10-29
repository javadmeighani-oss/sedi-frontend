import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/theme/app_theme.dart';
import 'package:sedi_app/features/lifestyle/presentation/lifestyle_l10n.dart';
import 'package:sedi_app/features/lifestyle/presentation/pages/lifestyle_page.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('Lifestyle hub is a Shell-canvas 5-card destination with subtitles', () {
    final page = _read(
      'lib/features/lifestyle/presentation/pages/lifestyle_page.dart',
    );
    final l10nSrc = _read(
      'lib/features/lifestyle/presentation/lifestyle_l10n.dart',
    );

    expect(page.contains('Color(0xFFDCE0C0)'), isTrue);
    expect(page.contains('gate3PaleOliveBackground'), isFalse);
    expect(page.contains('A3PageAppBar'), isTrue);
    expect(page.contains('LifestyleHealthPage'), isTrue);
    expect(page.contains('LifestyleHistoryPage'), isTrue);
    expect(page.contains('LifestyleSchedulePage'), isTrue);
    expect(page.contains('LifestyleNutritionPage'), isTrue);
    expect(page.contains('LifestyleExercisePage'), isTrue);
    expect(page.contains('lifestyle_weekly_plan_view'), isFalse);
    expect(page.contains('openLifestyleChat'), isTrue);
    expect(page.contains('Navigator.of(context).popUntil'), isTrue);

    expect('LifestyleHealthPage'.allMatches(page).length, 1);
    expect(page.contains('LifestyleSleepPage'), isFalse);
    expect(page.contains('LifestyleWaterPage'), isFalse);
    expect(page.contains('LifestyleMoodPage'), isFalse);

    expect(l10nSrc.contains('healthSubtitle'), isTrue);
    expect(l10nSrc.contains('historySubtitle'), isTrue);
    expect(l10nSrc.contains('scheduleSubtitle'), isTrue);
    expect(l10nSrc.contains('nutritionSubtitle'), isTrue);
    expect(l10nSrc.contains('exerciseSubtitle'), isTrue);
  });

  test('canonical titles unchanged; EN/FA/AR subtitles present', () {
    const titlesEn = [
      'Health',
      'My History',
      'My Schedule',
      'Nutrition Plan',
      'Exercise Plan',
    ];
    expect(LifestyleL10n('en').sectionTitles, titlesEn);
    expect(LifestyleL10n('en').sectionTitles.length, 5);
    expect(LifestyleL10n('fa').sectionTitles, [
      'سلامت',
      'تاریخچه من',
      'برنامه من',
      'برنامه تغذیه',
      'برنامه ورزش',
    ]);
    expect(LifestyleL10n('ar').sectionTitles, [
      'الصحة',
      'سجلي',
      'جدولي',
      'خطة التغذية',
      'خطة التمرين',
    ]);

    for (final lang in ['en', 'fa', 'ar']) {
      final l10n = LifestyleL10n(lang);
      expect(l10n.sectionSubtitles.length, 5);
      for (final subtitle in l10n.sectionSubtitles) {
        expect(subtitle.trim().isNotEmpty, isTrue);
      }
      expect(l10n.sectionTitles.toSet().length, 5);
    }
    expect(LifestyleL10n('en').isRtl, isFalse);
    expect(LifestyleL10n('fa').isRtl, isTrue);
    expect(LifestyleL10n('ar').isRtl, isTrue);
    expect(
      LifestyleL10n('en').healthSubtitle,
      'Health trends and recent measurements',
    );
    expect(
      LifestyleL10n('fa').nutritionSubtitle,
      'برنامه هفتگی تغذیه شما',
    );
    expect(
      LifestyleL10n('ar').exerciseSubtitle,
      'خطتك الأسبوعية للتمرين',
    );
  });

  test('weekly-plan and Talk-to-Sedi files are not part of this hub delta', () {
    expect(
      File('lib/features/lifestyle/presentation/widgets/lifestyle_weekly_plan_view.dart')
          .existsSync(),
      isTrue,
    );
    final hub = _read(
      'lib/features/lifestyle/presentation/pages/lifestyle_page.dart',
    );
    expect(hub.contains('Gate3AssistantStarterBus.instance.publish'), isTrue);
    expect(hub.contains('popUntil((route) => route.isFirst)'), isTrue);
  });

  testWidgets('hub renders five tappable cards on the Shell canvas',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LifestylePage()));
    await tester.pump();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, const Color(0xFFDCE0C0));
    expect(scaffold.backgroundColor, isNot(AppTheme.gate3PaleOliveBackground));

    final l10n = LifestyleL10n('en');
    expect(find.text(l10n.title), findsOneWidget);
    for (final title in l10n.sectionTitles) {
      expect(find.text(title), findsOneWidget);
    }
    for (final subtitle in l10n.sectionSubtitles) {
      expect(find.text(subtitle), findsOneWidget);
    }
    expect(find.byType(ListView), findsNothing); // pilot V1: the hub never scrolls
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.byIcon(Icons.history), findsOneWidget);
    // pilot V1 (R-034): the schedule and exercise cards got new glyphs (calendar-check, dumbbell)
    expect(find.byIcon(Icons.event_available_outlined), findsOneWidget);
    expect(find.byIcon(Icons.restaurant_outlined), findsOneWidget);
    expect(find.byIcon(Icons.fitness_center_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
