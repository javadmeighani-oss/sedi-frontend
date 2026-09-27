import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/app.dart';
import 'package:sedi_app/core/locale/sedi_locale_controller.dart';
import 'package:sedi_app/core/locale/sedi_locale_registry.dart';
import 'package:sedi_app/data/dto/auth/me_profile.dart';
import 'package:sedi_app/data/dto/auth/otp_request.dart';
import 'package:sedi_app/features/auth_otp/presentation/a2_language_sync.dart';
import 'package:sedi_app/features/auth_otp/presentation/a2_phone_e164.dart';
import 'package:sedi_app/features/auth_otp/presentation/a2_otp_error_mapper.dart';
import 'package:sedi_app/features/auth_otp/presentation/a2_stable_enable.dart';
import 'package:sedi_app/features/auth_otp/presentation/gate2_otp_input.dart';
import 'package:sedi_app/features/auth_otp/presentation/gate2_widgets.dart';
import 'package:sedi_app/features/auth_otp/presentation/gate2_post_otp_router.dart';
import 'package:sedi_app/features/auth_otp/presentation/gate2_post_otp_safe_router.dart';
import 'package:sedi_app/features/auth_otp/presentation/otp_login_localization.dart';
import 'package:sedi_app/features/auth_otp/presentation/pages/otp_login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SediLocaleController.instance.debugResetForTest();
  });

  group('A2 language immediate UI + direction', () {
    testWidgets('selecting fa immediately gives Persian + RTL', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _LanguageProbe(initial: null),
        ),
      );
      await tester.tap(find.text('فارسی'));
      await tester.pumpAndSettle();
      final dir = tester.widget<Directionality>(find.byType(Directionality).last);
      expect(dir.textDirection, TextDirection.rtl);
      expect(find.text('تأیید'), findsOneWidget);
      expect(find.text('Confirm'), findsNothing);
      expect(SediLocaleController.instance.languageCode, 'fa');
    });

    testWidgets('selecting ar immediately gives Arabic + RTL', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _LanguageProbe(initial: null),
        ),
      );
      await tester.tap(find.text('العربية'));
      await tester.pumpAndSettle();
      final dir = tester.widget<Directionality>(find.byType(Directionality).last);
      expect(dir.textDirection, TextDirection.rtl);
      expect(find.text('تأكيد'), findsOneWidget);
      expect(SediLocaleController.instance.languageCode, 'ar');
    });

    testWidgets('selecting en gives English + LTR', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _LanguageProbe(initial: null),
        ),
      );
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      final dir = tester.widget<Directionality>(find.byType(Directionality).last);
      expect(dir.textDirection, TextDirection.ltr);
      expect(find.text('Confirm'), findsOneWidget);
      expect(SediLocaleController.instance.languageCode, 'en');
    });

    testWidgets('Confirm disabled before selection and during 300ms',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _LanguageProbe(initial: null),
        ),
      );
      final before = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(before.onPressed, isNull);

      await tester.tap(find.text('English'));
      // Do not pumpAndSettle — that would drain the 300ms stable-enable timer.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final during = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(during.onPressed, isNull);

      await tester.pump(const Duration(milliseconds: 320));
      final after = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(after.onPressed, isNotNull);
    });

    testWidgets('no auto-navigation after language selection', (tester) async {
      var advanced = false;
      await tester.pumpWidget(
        MaterialApp(
          home: _LanguageProbe(
            initial: null,
            onConfirm: () => advanced = true,
          ),
        ),
      );
      await tester.tap(find.text('فارسی'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 320));
      expect(advanced, isFalse);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(advanced, isTrue);
    });
  });

  group('A2 language backend sync', () {
    test('selected language syncs via PATCH when backend differs', () {
      const me = MeProfileDto(userId: 1, preferredLanguage: 'en');
      expect(
        A2LanguageSync.needsPatch(backendMe: me, selectedLanguage: 'fa'),
        isTrue,
      );
      final dto = A2LanguageSync.patchDto('fa');
      expect(dto.toJson()['preferred_language'], 'fa');
    });

    test('no PATCH when preferred_language already matches', () {
      const me = MeProfileDto(userId: 1, preferredLanguage: 'fa');
      expect(
        A2LanguageSync.needsPatch(backendMe: me, selectedLanguage: 'fa'),
        isFalse,
      );
    });

    test('PATCH failure blocks A3', () {
      const me = MeProfileDto(userId: 1, preferredLanguage: 'en');
      final r = A2LanguageSync.classifyAfterPatchAttempt(
        backendMeBeforePatch: me,
        selectedLanguage: 'fa',
        patchOk: false,
        patchedProfile: null,
      );
      expect(r.mayEnterA3, isFalse);
    });
  });

  group('A2 OTP error code mapping', () {
    test('OTP_INVALID / OTP_EXPIRED / TOO_MANY_ATTEMPTS / OTP_REQUEST_FAILED',
        () {
      const fa = OtpLoginLocalization('fa');
      expect(
        A2OtpErrorMapper.mapVerify(l10n: fa, code: 'OTP_INVALID'),
        fa.otpInvalid,
      );
      expect(
        A2OtpErrorMapper.mapVerify(l10n: fa, code: 'OTP_EXPIRED'),
        fa.otpExpired,
      );
      expect(
        A2OtpErrorMapper.mapVerify(l10n: fa, code: 'TOO_MANY_ATTEMPTS'),
        fa.tooManyOtp,
      );
      expect(
        A2OtpErrorMapper.mapRequest(l10n: fa, code: 'OTP_REQUEST_FAILED'),
        fa.genericOtpRequestFailed,
      );

      const en = OtpLoginLocalization('en');
      expect(
        A2OtpErrorMapper.mapVerify(l10n: en, code: 'OTP_INVALID'),
        en.otpInvalid,
      );
      const ar = OtpLoginLocalization('ar');
      expect(
        A2OtpErrorMapper.mapVerify(l10n: ar, code: 'OTP_EXPIRED'),
        ar.otpExpired,
      );
    });

    test('OTP_REQUEST_FAILED + Too many OTP maps to tooManyOtp', () {
      const en = OtpLoginLocalization('en');
      const fa = OtpLoginLocalization('fa');
      const ar = OtpLoginLocalization('ar');
      const msg = 'Too many OTP requests. Try again later.';
      expect(
        A2OtpErrorMapper.mapRequest(
          l10n: en,
          code: 'OTP_REQUEST_FAILED',
          message: msg,
        ),
        en.tooManyOtp,
      );
      expect(
        A2OtpErrorMapper.mapRequest(
          l10n: fa,
          code: 'OTP_REQUEST_FAILED',
          message: msg,
        ),
        fa.tooManyOtp,
      );
      expect(
        A2OtpErrorMapper.mapRequest(
          l10n: ar,
          code: 'OTP_REQUEST_FAILED',
          message: 'too many requests',
        ),
        ar.tooManyOtp,
      );
    });

    test('OTP_REQUEST_FAILED provider failure stays generic', () {
      const en = OtpLoginLocalization('en');
      expect(
        A2OtpErrorMapper.mapRequest(
          l10n: en,
          code: 'OTP_REQUEST_FAILED',
          message: 'SMS delivery failed. Please try again later.',
        ),
        en.genericOtpRequestFailed,
      );
    });

    test('503 and network map correctly on request', () {
      const en = OtpLoginLocalization('en');
      expect(
        A2OtpErrorMapper.mapRequest(
          l10n: en,
          statusCode: 503,
        ),
        en.serverUnavailable,
      );
      expect(
        A2OtpErrorMapper.mapRequest(
          l10n: en,
          message: 'SocketException: Connection failed',
        ),
        en.networkError,
      );
    });

    test('verify mappings unchanged for expired/invalid heuristics', () {
      const en = OtpLoginLocalization('en');
      expect(
        A2OtpErrorMapper.mapVerify(l10n: en, message: 'OTP expired'),
        en.otpExpired,
      );
      expect(
        A2OtpErrorMapper.mapVerify(l10n: en, message: 'invalid code'),
        en.otpInvalid,
      );
    });
  });

  group('A2 OTP language invariance (request shape)', () {
    test('OtpRequestDto wire body is phone+purpose only', () {
      final login = const OtpRequestDto(
        phone: '+989121234567',
        purpose: OtpPurpose.login,
      ).toJson();
      expect(login.keys.toSet(), {'phone', 'purpose'});
      expect(login['purpose'], 'LOGIN');
      expect(login.containsKey('language'), isFalse);
      expect(login.containsKey('Accept-Language'), isFalse);

      final registration = const OtpRequestDto(
        phone: '+989121234567',
        purpose: OtpPurpose.registration,
      ).toJson();
      expect(registration['purpose'], 'REGISTRATION');
    });
  });

  group('A2 OTP no auto-submit + authority', () {
    test('six-digit complete does not imply verify action (helper only)', () {
      expect(OtpInputHelper.isComplete('123456'), isTrue);
      // Verify requires explicit CTA; StableEnable starts disabled.
      final c = A2StableEnableController(
        delay: A2StableEnableController.targetDelay,
      );
      c.sync(isValid: true, signature: '123456');
      expect(c.enabled, isFalse);
      c.dispose();
    });

    test('OTP fallback cannot enter A3', () {
      const me = MeProfileDto(
        userId: 7,
        phone: '+989121234567',
        name: 'Ali',
        sex: 'male',
        preferredLanguage: 'fa',
        calendarType: 'jalali',
        birthDay: 1,
        birthMonth: 1,
        birthYear: 1370,
        dateOfBirth: '1991-03-21',
      );
      final action = Gate2PostOtpSafeRouter.resolve(
        meSource: PostOtpMeSource.otpFallbackDraft,
        isNewUserPath: false,
        me: me,
        registrationDraftComplete: true,
      );
      expect(action, isNot(Gate2PostOtpAction.enterGate3));
      expect(
        Gate2PostOtpSafeRouter.requiresBackendConfirmedProfile(
          Gate2PostOtpAction.enterGate3,
        ),
        isTrue,
      );
    });

    test('backend-confirmed profile required before A3', () {
      const me = MeProfileDto(
        userId: 7,
        phone: '+989121234567',
        name: 'Ali',
        sex: 'male',
        preferredLanguage: 'en',
        calendarType: 'gregorian',
        birthDay: 1,
        birthMonth: 1,
        birthYear: 1990,
        dateOfBirth: '1990-01-01',
      );
      final backend = Gate2PostOtpSafeRouter.resolve(
        meSource: PostOtpMeSource.backendConfirmed,
        isNewUserPath: false,
        me: me,
        registrationDraftComplete: true,
      );
      expect(backend, Gate2PostOtpAction.enterGate3);
    });
  });

  group('A2 production-root MaterialLocalizations (SediApp delegates)', () {
    testWidgets('SediApp exposes Global Material/Widgets/Cupertino delegates',
        (tester) async {
      await tester.pumpWidget(const SediApp());
      await tester.pump();
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.localizationsDelegates, isNotNull);
      final delegates = app.localizationsDelegates!.toList();
      expect(delegates, containsAll(SediApp.localizationDelegates));
      expect(app.supportedLocales, SediLocaleRegistry.supportedLocales);
      // Flush IntroPage timers.
      await tester.pump(const Duration(milliseconds: 4000));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('FA returning TextField has MaterialLocalizations via SediApp',
        (tester) async {
      await _pumpOtpReturningWithRootLocale(tester, langCode: 'fa');
      expect(find.byType(TextFormField), findsWidgets);
      expect(tester.takeException(), isNull);
      expect(
        Localizations.localeOf(tester.element(find.byType(OtpLoginPage))),
        const Locale('fa'),
      );
    });

    testWidgets('AR returning TextField has MaterialLocalizations via SediApp',
        (tester) async {
      await _pumpOtpReturningWithRootLocale(tester, langCode: 'ar');
      expect(find.byType(TextFormField), findsWidgets);
      expect(tester.takeException(), isNull);
      expect(
        Localizations.localeOf(tester.element(find.byType(OtpLoginPage))),
        const Locale('ar'),
      );
    });

    testWidgets('EN returning TextField runtime remains valid via SediApp',
        (tester) async {
      await _pumpOtpReturningWithRootLocale(tester, langCode: 'en');
      expect(find.byType(TextFormField), findsWidgets);
      expect(tester.takeException(), isNull);
      expect(
        Localizations.localeOf(tester.element(find.byType(OtpLoginPage))),
        const Locale('en'),
      );
    });
  });

  group('A2 phone prefix alignment', () {
    testWidgets('RTL page keeps one LTR prefix row vertically aligned',
        (tester) async {
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

      expect(find.byIcon(Icons.phone_outlined), findsOneWidget);
      expect(find.text('+98'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
      expect(find.text('9121234567'), findsOneWidget);

      final dial = tester.widget<Text>(find.text('+98'));
      expect(dial.textDirection, TextDirection.ltr);
      final editable = tester.widget<EditableText>(
        find.descendant(
          of: find.byType(TextFormField),
          matching: find.byType(EditableText),
        ),
      );
      expect(editable.textDirection, TextDirection.ltr);

      final field = tester.getRect(find.byType(TextFormField));
      final icon = tester.getRect(find.byIcon(Icons.phone_outlined));
      final code = tester.getRect(find.text('+98'));
      final chevron = tester.getRect(find.byIcon(Icons.arrow_drop_down));
      final number = tester.getRect(find.text('9121234567'));

      expect(icon.left - field.left, inInclusiveRange(16, 36));
      expect(icon.center.dx, lessThan(field.center.dx));
      expect(icon.right, lessThan(code.left));
      expect(code.right, lessThanOrEqualTo(chevron.left));
      expect(chevron.right, lessThanOrEqualTo(number.left));

      expect((icon.center.dy - code.center.dy).abs(), lessThan(2));
      expect((code.center.dy - chevron.center.dy).abs(), lessThan(2));
      expect((icon.center.dy - number.center.dy).abs(), lessThan(5));
    });
  });
}

/// Production-root locale + delegates from [SediApp], home = [OtpLoginPage].
Future<void> _pumpOtpReturningWithRootLocale(
  WidgetTester tester, {
  required String langCode,
}) async {
  await SediLocaleController.instance.setRuntimeLocale(
    langCode,
    persistBootstrapCache: false,
  );

  await tester.pumpWidget(
    MaterialApp(
      locale: SediLocaleController.instance.current.locale,
      supportedLocales: SediLocaleRegistry.supportedLocales,
      localizationsDelegates: SediApp.localizationDelegates,
      builder: (context, child) => Directionality(
        textDirection: SediLocaleController.instance.current.textDirection,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const OtpLoginPage(),
    ),
  );
  await tester.pump();

  final langLabel = switch (langCode) {
    'fa' => 'فارسی',
    'ar' => 'العربية',
    _ => 'English',
  };
  await tester.tap(find.text(langLabel));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 320));
  final l10n = OtpLoginLocalization(langCode);
  await tester.tap(find.text(l10n.confirm));
  await tester.pumpAndSettle();

  await tester.tap(find.text(l10n.haveAccountTitle));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 320));
  await tester.tap(find.text(l10n.confirm));
  await tester.pumpAndSettle();
}

/// Minimal A2 language-step probe matching production behavior:
/// immediate l10n + direction on select; Confirm gated by 300ms stable enable.
class _LanguageProbe extends StatefulWidget {
  final String? initial;
  final VoidCallback? onConfirm;

  const _LanguageProbe({
    this.initial,
    this.onConfirm,
  });

  @override
  State<_LanguageProbe> createState() => _LanguageProbeState();
}

class _LanguageProbeState extends State<_LanguageProbe> {
  String? _language;
  final _cta = A2StableEnableController(
    delay: A2StableEnableController.targetDelay,
  );

  @override
  void initState() {
    super.initState();
    _language = widget.initial;
    _cta.addListener(() {
      if (mounted) setState(() {});
    });
    SediLocaleController.instance.addListener(_onGlobalLocale);
    _cta.sync(isValid: _language != null, signature: _language);
  }

  void _onGlobalLocale() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    SediLocaleController.instance.removeListener(_onGlobalLocale);
    _cta.dispose();
    super.dispose();
  }

  OtpLoginLocalization get _l10n => OtpLoginLocalization(
        _language ?? SediLocaleController.instance.languageCode,
      );

  Future<void> _select(String code) async {
    await SediLocaleController.instance.setRuntimeLocale(
      code,
      persistBootstrapCache: false,
    );
    setState(() {
      _language = code;
      _cta.sync(isValid: true, signature: _language);
    });
  }

  @override
  Widget build(BuildContext context) {
    final direction = SediLocaleController.instance.current.textDirection;
    return Directionality(
      textDirection: direction,
      child: Scaffold(
        body: Column(
          children: [
            TextButton(
              onPressed: () => _select('ar'),
              child: const Text('العربية'),
            ),
            TextButton(
              onPressed: () => _select('en'),
              child: const Text('English'),
            ),
            TextButton(
              onPressed: () => _select('fa'),
              child: const Text('فارسی'),
            ),
            ElevatedButton(
              onPressed: _cta.enabled ? widget.onConfirm ?? () {} : null,
              child: Text(_l10n.confirm),
            ),
          ],
        ),
      ),
    );
  }
}
