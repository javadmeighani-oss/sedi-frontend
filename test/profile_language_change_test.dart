import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/locale/sedi_locale_controller.dart';
import 'package:sedi_app/core/locale/sedi_locale_registry.dart';
import 'package:sedi_app/core/network/api_error.dart';
import 'package:sedi_app/core/network/api_response.dart';
import 'package:sedi_app/data/dto/auth/me_profile.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/gate3_localization.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/profile_language_change.dart';
import 'package:shared_preferences/shared_preferences.dart';

MeProfileDto _me(String lang) =>
    MeProfileDto(userId: 1, preferredLanguage: lang);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SediLocaleController locale;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    locale = SediLocaleController.forTest(initial: SediLocaleRegistry.fa);
  });

  test('backend-confirmed switch changes the app language and sends only preferred_language',
      () async {
    MeUpdateDto? sent;
    final outcome = await ProfileLanguageChange.apply(
      current: 'fa',
      selected: 'ar',
      locale: locale,
      patch: (u) async {
        sent = u;
        return ApiResponse(ok: true, data: _me('ar'));
      },
    );
    expect(outcome, ProfileLanguageOutcome.changed);
    expect(sent!.toJson(), {'preferred_language': 'ar'});
    expect(locale.languageCode, 'ar');
    expect(locale.isRtl, isTrue);
  });

  test('switching to English flips the direction to LTR', () async {
    final outcome = await ProfileLanguageChange.apply(
      current: 'fa',
      selected: 'en',
      locale: locale,
      patch: (u) async => ApiResponse(ok: true, data: _me('en')),
    );
    expect(outcome, ProfileLanguageOutcome.changed);
    expect(locale.languageCode, 'en');
    expect(locale.isRtl, isFalse);
  });

  test('failed PATCH keeps the old language', () async {
    final outcome = await ProfileLanguageChange.apply(
      current: 'fa',
      selected: 'en',
      locale: locale,
      patch: (u) async => ApiResponse<MeProfileDto>(
        ok: false,
        error: ApiError(code: 'NETWORK_ERROR', message: 'offline'),
      ),
    );
    expect(outcome, ProfileLanguageOutcome.failed);
    expect(locale.languageCode, 'fa');
  });

  test('backend answering with another language is not applied', () async {
    final outcome = await ProfileLanguageChange.apply(
      current: 'fa',
      selected: 'en',
      locale: locale,
      patch: (u) async => ApiResponse(ok: true, data: _me('fa')),
    );
    expect(outcome, ProfileLanguageOutcome.failed);
    expect(locale.languageCode, 'fa');
  });

  test('choosing the current language sends nothing', () async {
    var called = false;
    final outcome = await ProfileLanguageChange.apply(
      current: 'fa',
      selected: 'fa',
      locale: locale,
      patch: (u) async {
        called = true;
        return ApiResponse(ok: true, data: _me('fa'));
      },
    );
    expect(outcome, ProfileLanguageOutcome.unchanged);
    expect(called, isFalse);
  });

  test('new strings exist in fa/ar/en and keep the brand out of the way', () {
    for (final lang in ['fa', 'ar', 'en']) {
      final l10n = Gate3Localization(lang);
      expect(l10n.profileLanguageChooseTitle.trim(), isNotEmpty);
      expect(l10n.profileLanguageChangeFailed.trim(), isNotEmpty);
    }
    expect(Gate3Localization('fa').profileLanguageChooseTitle,
        isNot(Gate3Localization('en').profileLanguageChooseTitle));
  });
}
