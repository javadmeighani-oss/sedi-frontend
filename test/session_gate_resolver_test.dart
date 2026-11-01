import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/auth/auth_profile_service.dart';
import 'package:sedi_app/core/auth/auth_refresh_service.dart';
import 'package:sedi_app/core/auth/auth_service.dart';
import 'package:sedi_app/core/auth/user_identity_service.dart';
import 'package:sedi_app/core/navigation/app_gate.dart';
import 'package:sedi_app/core/navigation/session_gate_resolver.dart';
import 'package:sedi_app/core/network/api_error.dart';
import 'package:sedi_app/core/network/api_response.dart';
import 'package:sedi_app/core/utils/user_profile_manager.dart';
import 'package:sedi_app/data/dto/auth/me_profile.dart';
import 'package:sedi_app/data/models/user_profile.dart';
import 'package:sedi_app/features/intro/presentation/pages/intro_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthProfileService extends AuthProfileService {
  _FakeAuthProfileService(this._responses);

  final List<ApiResponse<MeProfileDto>> _responses;
  int fetchCount = 0;
  int cacheCount = 0;

  @override
  Future<ApiResponse<MeProfileDto>> fetchMe({
    String? accessToken,
    bool recoverSessionOn401 = true,
  }) async {
    final idx = fetchCount.clamp(0, _responses.length - 1);
    fetchCount++;
    return _responses[idx];
  }

  @override
  Future<void> cacheProfileFromBackend(MeProfileDto me) async {
    cacheCount++;
    await super.cacheProfileFromBackend(me);
  }
}

MeProfileDto _okMe() => MeProfileDto(
      userId: 42,
      phone: '+989121234567',
      name: 'Sara',
      preferredLanguage: 'fa',
    );

ApiResponse<MeProfileDto> _ok() => ApiResponse<MeProfileDto>(
      ok: true,
      data: _okMe(),
      statusCode: 200,
    );

ApiResponse<MeProfileDto> _unauthorized() => ApiResponse<MeProfileDto>(
      ok: false,
      error: const ApiError(code: 'UNAUTHORIZED', message: '401'),
      statusCode: 401,
    );

ApiResponse<MeProfileDto> _network() => ApiResponse<MeProfileDto>(
      ok: false,
      error: const ApiError(code: 'NETWORK_ERROR', message: 'offline'),
      statusCode: null,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    AuthService.resetForTest();
    await AuthService.clearUserData();
    await UserProfileManager.clearProfile();
    UserIdentityService.clearCache();
  });

  group('A1 session authority', () {
    test('no-session → A2', () async {
      final result = await SessionGateResolver.resolveColdStart(
        profileService: _FakeAuthProfileService([_ok()]),
      );
      expect(result.status, SessionResolveStatus.noSession);
      expect(result.nextGate, SediAppGate.login);
    });

    test('local profile alone cannot authorize A3', () async {
      await AuthService.setTokens(
        accessToken: 'stale-access',
        refreshToken: 'stale-refresh',
      );
      await UserProfileManager.saveProfile(
        UserProfile(
          name: 'Sara',
          phoneNumber: '+989121234567',
          userId: 42,
          isVerified: true,
          preferredLanguage: 'fa',
        ),
      );

      // Backend rejects — local profile must not short-circuit to A3.
      final fake = _FakeAuthProfileService([_unauthorized()]);
      final result = await SessionGateResolver.resolveColdStart(
        profileService: fake,
        tryRefresh: () async => false,
      );

      expect(fake.fetchCount, greaterThanOrEqualTo(1));
      expect(result.nextGate, SediAppGate.login);
      expect(result.status, SessionResolveStatus.authInvalid);
      expect(await AuthService.hasToken(), isFalse);
    });

    test('valid stored session + /auth/me success → A3', () async {
      await AuthService.setTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
      );
      final fake = _FakeAuthProfileService([_ok()]);
      final result = await SessionGateResolver.resolveColdStart(
        profileService: fake,
      );

      expect(result.status, SessionResolveStatus.authenticated);
      expect(result.nextGate, SediAppGate.heart);
      expect(fake.cacheCount, 1);
    });

    test('/auth/me 401 + refresh success → A3', () async {
      await AuthService.setTokens(
        accessToken: 'expired',
        refreshToken: 'refresh',
      );
      final fake = _FakeAuthProfileService([_unauthorized(), _ok()]);
      final result = await SessionGateResolver.resolveColdStart(
        profileService: fake,
        tryRefresh: () async {
          await AuthService.setTokens(
            accessToken: 'new-access',
            refreshToken: 'new-refresh',
          );
          return true;
        },
      );

      expect(fake.fetchCount, 2);
      expect(result.status, SessionResolveStatus.authenticated);
      expect(result.nextGate, SediAppGate.heart);
    });

    test('/auth/me 401 + refresh fail → A2', () async {
      await AuthService.setTokens(
        accessToken: 'expired',
        refreshToken: 'bad-refresh',
      );
      UserIdentityService.debugSetCachedUserId(99);
      final fake = _FakeAuthProfileService([_unauthorized()]);
      final result = await SessionGateResolver.resolveColdStart(
        profileService: fake,
        tryRefresh: () async => false,
      );

      expect(result.status, SessionResolveStatus.authInvalid);
      expect(result.nextGate, SediAppGate.login);
      expect(await AuthService.hasToken(), isFalse);
      expect(UserIdentityService.debugCachedUserId(), isNull);
    });

    test('/auth/me 401 + refresh timeout keeps tokens and stays on A1',
        () async {
      await AuthService.setTokens(
        accessToken: 'expired',
        refreshToken: 'refresh',
      );
      UserIdentityService.debugSetCachedUserId(42);
      final fake = _FakeAuthProfileService([_unauthorized()]);
      final result = await SessionGateResolver.resolveColdStart(
        profileService: fake,
        refreshOnce: () async => AuthRefreshOutcome.transientFailure,
      );

      expect(result.status, SessionResolveStatus.backendUnavailable);
      expect(result.stayOnStartup, isTrue);
      expect(result.nextGate, SediAppGate.splash);
      expect(result.nextGate, isNot(SediAppGate.login));
      expect(result.nextGate, isNot(SediAppGate.heart));
      expect(await AuthService.hasToken(), isTrue);
      expect(UserIdentityService.debugCachedUserId(), 42);
    });

    test('backend unavailable keeps tokens and does not route A2/A3',
        () async {
      await AuthService.setTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
      );
      UserIdentityService.debugSetCachedUserId(42);
      final fake = _FakeAuthProfileService([_network()]);
      final result = await SessionGateResolver.resolveColdStart(
        profileService: fake,
      );

      expect(result.status, SessionResolveStatus.backendUnavailable);
      expect(result.stayOnStartup, isTrue);
      expect(result.nextGate, SediAppGate.splash);
      expect(result.nextGate, isNot(SediAppGate.login));
      expect(result.nextGate, isNot(SediAppGate.heart));
      expect(await AuthService.hasToken(), isTrue);
      expect(UserIdentityService.debugCachedUserId(), 42);
    });

    test('transient then recovered backend revalidates to A3', () async {
      await AuthService.setTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
      );
      final fake = _FakeAuthProfileService([_network(), _ok()]);
      final first = await SessionGateResolver.resolveColdStart(
        profileService: fake,
      );
      expect(first.stayOnStartup, isTrue);
      expect(first.nextGate, isNot(SediAppGate.login));
      expect(await AuthService.hasToken(), isTrue);

      final recovered = await SessionGateResolver.resolveColdStart(
        profileService: fake,
      );
      expect(recovered.status, SessionResolveStatus.authenticated);
      expect(recovered.nextGate, SediAppGate.heart);
      expect(fake.cacheCount, 1);
      expect(await AuthService.hasToken(), isTrue);
    });
  });

  group('A1 intro', () {
    test('approved visual contract constants', () {
      expect(IntroPage.kIntroDuration, const Duration(milliseconds: 2200));
      expect(IntroPage.kBrandLatin, 'Sedi.');
      expect(IntroPage.kMotionKeyframes.length, 3);
      expect(IntroPage.kMotionKeyframes[0], (0.00, 0.79, 0.05));
      expect(IntroPage.kMotionKeyframes[1], (0.50, 0.52, 0.24));
      expect(IntroPage.kMotionKeyframes[2], (1.00, 0.27, 0.52));
      expect(
        IntroPage.kHorizonAsset,
        'assets/images/cosmic_sunrise_background.png',
      );
      expect(IntroPage.kReconnectRetryDelay, const Duration(seconds: 2));
    });

    test('horizon asset recovered on disk and wired in IntroPage source', () {
      final src = File(
        'lib/features/intro/presentation/pages/intro_page.dart',
      ).readAsStringSync();
      expect(src.contains('cosmic_sunrise_background.png'), isTrue);
      expect(src.contains('kMotionKeyframes'), isTrue);
      expect(src.contains('sampleMotion'), isTrue);
      expect(src.contains('kReconnectRetryDelay'), isTrue);
      expect(src.contains('session.stayOnStartup'), isTrue);
      expect(src.contains('while (session.stayOnStartup)'), isTrue);
      expect(src.contains('Reconnecting'), isFalse);
      expect(src.contains('temporarily unreachable'), isFalse);
      expect(src.contains('AuthService.clearUserData'), isFalse);
      expect(
        File('assets/images/cosmic_sunrise_background.png').existsSync(),
        isTrue,
      );
    });

    testWidgets('IntroPage appears on app open with horizon Image.asset',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: IntroPage()));
      expect(find.byType(IntroPage), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      final usesHorizon = images.any((img) {
        final provider = img.image;
        return provider is AssetImage &&
            provider.assetName == IntroPage.kHorizonAsset;
      });
      expect(usesHorizon, isTrue);
      // Advance partially through the 3s birth animation.
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.byType(IntroPage), findsOneWidget);
      // Flush remaining intro / health timers before dispose.
      await tester.pump(const Duration(milliseconds: 4000));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });
}
