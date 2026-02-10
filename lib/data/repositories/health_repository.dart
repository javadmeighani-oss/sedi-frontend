/// Health repository: POST /health/add (vitals), GET latest (try multiple endpoints).
/// See: frontend/docs/FRONTEND_BACKEND_ALIGNMENT.md
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_error.dart';
import '../../core/network/api_response.dart';
import '../dto/health_data_create.dart';
import '../dto/health_data_response.dart';

/// Endpoints tried in order for fetchLatestHealthData (stop at first success).
const List<String> _latestEndpoints = ['/health/latest', '/health/context', '/health'];

class HealthRepository {
  final ApiClient _client;

  HealthRepository({String? baseUrl, ApiClient? apiClient})
      : _client = apiClient ?? ApiClient(baseUrl: baseUrl ?? AppConfig.baseUrl);

  /// POST /health/add — add health data (vitals).
  /// Returns ApiResponse with parsed data (health_id, user_id, notification_id, message) or error.
  Future<ApiResponse<HealthDataResponse?>> addHealthData(HealthDataCreate req) async {
    return _client.post<HealthDataResponse?>(
      '/health/add',
      body: req.toJson(),
      parser: (v) {
        if (v == null) return null;
        final map = v is Map ? Map<String, dynamic>.from(v) : null;
        return map != null ? HealthDataResponse.fromJson(map) : null;
      },
    );
  }

  /// Fetch latest health data. Tries GET endpoints in order; stops at first success.
  /// Data may be a single object or a list (newest by created_at chosen if list).
  /// Returns first successful response; if all fail (404/405/network), returns last failure.
  Future<ApiResponse<HealthDataResponse?>> fetchLatestHealthData(int userId) async {
    final queryParams = {'user_id': userId.toString()};
    ApiResponse<HealthDataResponse?>? lastFailed;
    for (final path in _latestEndpoints) {
      final response = await _client.get<HealthDataResponse?>(
        path,
        queryParams: queryParams,
        parser: (v) => HealthDataResponse.fromApiData(v),
      );
      if (response.ok && response.data != null) return response;
      lastFailed = response;
    }
    return lastFailed ?? ApiResponse(ok: false, error: ApiError(message: 'No health endpoint available'));
  }
}
