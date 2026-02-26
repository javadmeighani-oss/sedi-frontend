import '../../data/dto/auth/otp_request.dart';
import '../../data/dto/auth/otp_verify.dart';
import '../../data/dto/auth/otp_verify_response.dart';
import '../network/api_client.dart';
import '../network/api_response.dart';

class AuthOtpService {
  final ApiClient _apiClient;

  AuthOtpService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<ApiResponse<Map<String, dynamic>>> requestOtp({
    required String phone,
    String? language,
  }) async {
    final dto = OtpRequestDto(phone: phone);
    final headers = <String, String>{};
    if (language != null && language.trim().isNotEmpty) {
      headers['Accept-Language'] = language.trim();
    }

    return _apiClient.postRaw(
      '/auth/request_otp',
      body: dto.toJson(),
      extraHeaders: headers.isEmpty ? null : headers,
    );
  }

  Future<ApiResponse<OtpVerifyResponse>> verifyOtp({
    required String phone,
    required String code,
    String? language,
  }) async {
    final dto = OtpVerifyDto(phone: phone, code: code);
    final headers = <String, String>{};
    if (language != null && language.trim().isNotEmpty) {
      headers['Accept-Language'] = language.trim();
    }

    final verifyResponse = await _apiClient.post<OtpVerifyResponse>(
      '/auth/verify_otp',
      body: dto.toJson(),
      extraHeaders: headers.isEmpty ? null : headers,
      parser: (json) {
        if (json is Map) {
          return OtpVerifyResponse.fromJson(Map<String, dynamic>.from(json));
        }
        return null;
      },
    );

    final payload = verifyResponse.data;
    final token = payload?.accessToken;
    final needsMeLookup = verifyResponse.ok &&
        payload != null &&
        token != null &&
        token.isNotEmpty;
    if (!needsMeLookup) {
      return verifyResponse;
    }

    final meResponse = await _apiClient.get<Map<String, dynamic>>(
      '/auth/me',
      extraHeaders: {
        'Authorization': 'Bearer $token',
      },
      parser: (json) => json is Map ? Map<String, dynamic>.from(json) : null,
    );
    if (!meResponse.ok || meResponse.data == null) {
      return verifyResponse;
    }

    final meData = meResponse.data!;
    final rawUserId = meData['user_id'];
    final userId = rawUserId is int
        ? rawUserId
        : int.tryParse(rawUserId?.toString() ?? '');
    final enriched = payload.copyWith(
      userId: userId,
      phone: meData['phone']?.toString(),
      language: meData['language']?.toString() ?? payload.language,
    );
    return ApiResponse<OtpVerifyResponse>(
      ok: verifyResponse.ok,
      data: enriched,
      error: verifyResponse.error,
      statusCode: verifyResponse.statusCode,
    );
  }
}
