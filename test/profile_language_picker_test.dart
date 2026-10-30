import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/locale/sedi_locale_controller.dart';
import 'package:sedi_app/core/locale/sedi_locale_registry.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/profile_language_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The profile language chooser (liquid-glass panel, letter badges) - Javad 2026-10-30.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Opens the panel and records what [ProfileLanguagePicker.show] finally returns into [out].
  Future<void> open(
    WidgetTester tester, {
    required String current,
    String uiLang = 'fa',
    List<String?>? out,
  }) async {
    SharedPreferences.setMockInitialValues({});
    await SediLocaleController.instance.setRuntimeLocale(uiLang, persistBootstrapCache: false);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  final value = await ProfileLanguagePicker.show(context, current: current);
                  out?.add(value);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('three options, each with its own script and a letter badge', (tester) async {
    await open(tester, current: 'en');
    expect(find.text('فارسی'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    for (final glyph in ['ف', 'ع', 'A']) {
      expect(find.text(glyph), findsOneWidget, reason: glyph);
    }
  });

  testWidgets('only the current language carries the check', (tester) async {
    await open(tester, current: 'ar');
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    final row = find.ancestor(of: find.text('العربية'), matching: find.byType(AnimatedContainer));
    expect(find.descendant(of: row.first, matching: find.byIcon(Icons.check_rounded)), findsOneWidget);
  });

  testWidgets('tapping a language returns its code and closes the panel', (tester) async {
    final out = <String?>[];
    await open(tester, current: 'en', uiLang: 'en', out: out);
    await tester.tap(find.text('فارسی'));
    await tester.pumpAndSettle();
    expect(out, ['fa']);
    expect(find.text('English'), findsNothing);
  });

  testWidgets('tapping outside dismisses with null', (tester) async {
    final out = <String?>[];
    await open(tester, current: 'fa', out: out);
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(out, [null]);
  });

  test('the letters', () {
    expect(SediLanguageGlyph.of('fa'), 'ف');
    expect(SediLanguageGlyph.of('AR'), 'ع');
    expect(SediLanguageGlyph.of('en'), 'A');
    expect(SediLanguageGlyph.of(null), '•');
    expect(SediLocaleRegistry.all.map((d) => SediLanguageGlyph.of(d.code)).toSet().length, 3);
  });
}
