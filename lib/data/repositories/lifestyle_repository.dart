/// Lifestyle: GET /lifestyle/context, POST /lifestyle/update.
/// See: frontend/docs/FRONTEND_BACKEND_ALIGNMENT.md
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../dto/lifestyle_data_create.dart';

class LifestyleRepository {
  final ApiClient _client;

  LifestyleRepository({String? baseUrl, ApiClient? apiClient})
      : _client = apiClient ?? ApiClient(baseUrl: baseUrl ?? AppConfig.baseUrl);

  Map<String, String> _userQuery(int userId) => {'user_id': userId.toString()};

  /// GET /lifestyle/context — fetch lifestyle context for user.
  Future<ApiResponse<Map<String, dynamic>?>> fetchContext(int userId) async {
    return _client.get<Map<String, dynamic>?>(
      '/lifestyle/context',
      queryParams: _userQuery(userId),
      parser: (v) => v == null ? null : (v is Map ? Map<String, dynamic>.from(v) : null),
    );
  }

  /// POST /lifestyle/update — update lifestyle data.
  Future<ApiResponse<Map<String, dynamic>?>> updateLifestyle(LifestyleDataCreate req) async {
    return _client.post<Map<String, dynamic>?>(
      '/lifestyle/update',
      body: req.toJson(),
      parser: (v) => v == null ? null : (v is Map ? Map<String, dynamic>.from(v) : null),
    );
  }
}
