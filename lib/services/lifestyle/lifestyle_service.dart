import '../../core/network/api_response.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_error.dart';
import '../../data/dto/lifestyle/lifestyle_get_response_dto.dart';
import '../../data/dto/lifestyle/lifestyle_update_request_dto.dart';
import '../../data/models/lifestyle_state.dart';

class LifestyleService {
  final ApiClient _apiClient;

  LifestyleService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<ApiResponse<LifestyleState>> getLifestyle(
      {required int userId}) async {
    final response = await _apiClient.get<LifestyleGetResponseDto>(
      '/lifestyle/context',
      queryParams: {'user_id': userId.toString()},
      parser: (json) {
        if (json is Map) {
          return LifestyleGetResponseDto.fromJson(
              Map<String, dynamic>.from(json));
        }
        return null;
      },
    );

    return ApiResponse<LifestyleState>(
      ok: response.ok,
      data: response.data != null
          ? LifestyleState.fromDto(response.data!)
          : const LifestyleState(),
      error: response.error,
      statusCode: response.statusCode,
    );
  }

  Future<ApiResponse<void>> updateLifestyle({
    required int userId,
    required LifestyleUpdateRequestDto req,
  }) async {
    if (req.userId != userId) {
      return const ApiResponse<void>(
        ok: false,
        error: ApiError(
            code: 'USER_ID_MISMATCH', message: 'Request user_id mismatch'),
      );
    }
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/lifestyle/update',
      body: req.toJson(),
      parser: (json) {
        if (json is Map) return Map<String, dynamic>.from(json);
        return null;
      },
    );
    return ApiResponse<void>(
      ok: response.ok,
      error: response.error,
      statusCode: response.statusCode,
    );
  }
}
