import '../../data/dto/auth/auth_me_response_parser.dart';
import '../../data/dto/auth/me_profile.dart';
import '../../data/dto/auth/me_profile_parser.dart';
import '../../data/dto/auth/otp_verify_response.dart';
import '../../data/dto/auth/post_otp_profile_fallback.dart';
import '../../data/models/user_profile.dart';
import '../network/api_client.dart';
import '../network/api_error.dart';
import '../network/api_response.dart';
import '../profile/profile_snapshot_cache.dart';
import '../utils/user_profile_manager.dart';
import 'user_identity_service.dart';

/// Backend profile source of truth: GET/PATCH /auth/me.
class AuthProfileService {
  final ApiClient _apiClient;

  AuthProfileService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(timeout: const Duration(seconds: 30));

  /// Generic GET `/auth/me` via shared ApiResponse envelope parsing.
  Future<ApiResponse<MeProfileDto>> fetchMe({
    String? accessToken,
    bool recoverSessionOn401 = true,
  }) async {
    return _apiClient.get<MeProfileDto>(
      '/auth/me',
      accessToken: accessToken,
      recoverSessionOn401: recoverSessionOn401,
      parser: parseMeProfileDto,
    );
  }

  /// Gate 2 post-OTP GET `/auth/me` using endpoint-specific parsing.
  ///
  /// [knownPhoneE164] is the OTP-confirmed phone and may be used only when the
  /// backend profile omits `phone` after a successful OTP verify.
  Future<ApiResponse<MeProfileDto>> fetchMeAfterOtp({
    required String accessToken,
    String? knownPhoneE164,
  }) async {
    var result = await _fetchMeAfterOtpOnce(
      accessToken: accessToken,
      knownPhoneE164: knownPhoneE164,
    );
    if (result.ok || !_isTransientMeFailure(result)) {
      return result;
    }

    await Future<void>.delayed(const Duration(milliseconds: 450));
    return _fetchMeAfterOtpOnce(
      accessToken: accessToken,
      knownPhoneE164: knownPhoneE164,
    );
  }

  Future<ApiResponse<MeProfileDto>> _fetchMeAfterOtpOnce({
    required String accessToken,
    String? knownPhoneE164,
  }) async {
    try {
      final response = await _apiClient.getHttpResponse(
        '/auth/me',
        accessToken: accessToken,
        recoverSessionOn401: false,
      );
      return AuthMeResponseParser.parseHttpResponse(
        statusCode: response.statusCode,
        body: response.body,
        knownPhoneE164: knownPhoneE164,
      ).toApiResponse();
    } catch (e) {
      final msg = e.toString();
      String code = 'NETWORK_ERROR';
      if (msg.toLowerCase().contains('timeout')) code = 'TIMEOUT';
      return ApiResponse<MeProfileDto>(
        ok: false,
        error: ApiError(code: code, message: msg),
        statusCode: null,
      );
    }
  }

  /// Fallback profile when GET `/auth/me` fails but OTP verify confirmed identity.
  MeProfileDto? profileFromOtpVerify(
    OtpVerifyResponse verify, {
    String? fallbackPhoneE164,
  }) {
    return postOtpProfileFromVerify(
      verify,
      fallbackPhoneE164: fallbackPhoneE164,
    );
  }

  static bool _isTransientMeFailure(ApiResponse<MeProfileDto> meRes) {
    if (meRes.ok) return false;
    final status = meRes.statusCode;
    if (status == null) return true;
    return status >= 500;
  }

  Future<ApiResponse<MeProfileDto>> patchMe(
    MeUpdateDto update, {
    String? accessToken,
    String? knownPhoneE164,
    bool recoverSessionOn401 = true,
  }) async {
    try {
      final response = await _apiClient.patchHttpResponse(
        '/auth/me',
        body: update.toJson(),
        accessToken: accessToken,
        recoverSessionOn401: recoverSessionOn401,
      );
      return AuthMeResponseParser.parseHttpResponse(
        statusCode: response.statusCode,
        body: response.body,
        knownPhoneE164: knownPhoneE164,
      ).toApiResponse();
    } catch (e) {
      final msg = e.toString();
      String code = 'NETWORK_ERROR';
      if (msg.toLowerCase().contains('timeout')) code = 'TIMEOUT';
      return ApiResponse<MeProfileDto>(
        ok: false,
        error: ApiError(code: code, message: msg),
        statusCode: null,
      );
    }
  }

  /// GET /auth/me and persist confirmed backend profile locally.
  Future<ApiResponse<MeProfileDto>> fetchAndCacheProfile() async {
    final me = await fetchMe();
    if (!me.ok || me.data == null) return me;
    await cacheProfileFromBackend(me.data!);
    return me;
  }

  Future<void> cacheProfileFromBackend(MeProfileDto me) async {
    // A1 reads /auth/me for the session check anyway: the profile page is filled from this very answer (no new request).
    ProfileSnapshotCache.putMe(me);
    final existing = await UserProfileManager.loadProfile();
    final profile = existing.copyWith(
      userId: me.userId,
      phoneNumber: me.phone,
      name: me.name,
      preferredLanguage: me.preferredLanguage ?? existing.preferredLanguage,
      gender: _mapSexToGender(me.sex) ?? existing.gender,
      calendarType: me.calendarType ?? existing.calendarType,
      birthDay: me.birthDay ?? existing.birthDay,
      birthMonth: me.birthMonth ?? existing.birthMonth,
      birthYear: me.birthYear ?? existing.birthYear,
      dateOfBirth: me.dateOfBirth ?? existing.dateOfBirth,
      isVerified: true,
    );
    await UserProfileManager.saveProfile(profile);
    // Identity cache must reflect only this backend-confirmed account.
    UserIdentityService.adoptBackendConfirmedUserId(me.userId);
  }

  static String? _mapSexToGender(String? sex) {
    if (sex == null || sex.isEmpty) return null;
    final s = sex.toLowerCase();
    if (s == 'male' || s == 'female' || s == 'other') return s;
    return null;
  }

  static UserProfile toUserProfile(MeProfileDto me) {
    return UserProfile(
      userId: me.userId,
      phoneNumber: me.phone,
      name: me.name,
      preferredLanguage: me.preferredLanguage ?? 'en',
      gender: _mapSexToGender(me.sex),
      calendarType: me.calendarType,
      birthDay: me.birthDay,
      birthMonth: me.birthMonth,
      birthYear: me.birthYear,
      dateOfBirth: me.dateOfBirth,
      isVerified: true,
    );
  }
}
