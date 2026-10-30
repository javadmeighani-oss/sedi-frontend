import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/locale/sedi_locale_controller.dart';
import 'package:sedi_app/features/lifestyle/domain/schedule_today.dart';
import 'package:sedi_app/features/lifestyle/logic/lifestyle_summary_cache.dart';
import 'package:sedi_app/features/lifestyle/presentation/lifestyle_l10n.dart';
import 'package:sedi_app/features/lifestyle/presentation/pages/lifestyle_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lifestyle hub (phone test 2026-10-30): the today card, the small tiles that overflowed by 0.39 px, and the schedule
/// tile that said "everything is done" next to "no plan today".
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SediLocaleController.instance.setRuntimeLocale('fa', persistBootstrapCache: false);
    LifestyleSummaryCache.reset();
  });
  tearDown(LifestyleSummaryCache.reset);

  Future<void> pumpHub(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: LifestylePage()));
    await tester.pump(const Duration(milliseconds: 300));
  }

  test('the cache gives only a summary of TODAY', () {
    expect(LifestyleSummaryCache.today(), isNull);
    final noon = DateTime(2026, 10, 30, 12);
    LifestyleSummaryCache.seed(const ScheduleDaySummary(0, 0, null), now: noon);
    expect(LifestyleSummaryCache.today(now: noon), isNotNull);
    expect(LifestyleSummaryCache.today(now: noon.add(const Duration(days: 1))), isNull); // never yesterday's
  });

  for (final size in const [Size(360, 780), Size(360, 700), Size(360, 640), Size(411, 891)]) {
    testWidgets('no overflow with the today card on top at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      LifestyleSummaryCache.seed(const ScheduleDaySummary(0, 0, null));
      await pumpHub(tester, size);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('nothing planned today: the schedule tile does not claim everything is done', (tester) async {
    LifestyleSummaryCache.seed(const ScheduleDaySummary(0, 0, null));
    await pumpHub(tester, const Size(360, 780));
    final l10n = LifestyleL10n('fa');
    expect(find.text(l10n.hubScheduleLine(0)), findsNothing);
    expect(find.text(l10n.scheduleSubtitle), findsOneWidget);
  });

  testWidgets('with something left today the tile says how much', (tester) async {
    LifestyleSummaryCache.seed(const ScheduleDaySummary(3, 1, null));
    await pumpHub(tester, const Size(360, 780));
    expect(find.text(LifestyleL10n('fa').hubScheduleLine(2)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
