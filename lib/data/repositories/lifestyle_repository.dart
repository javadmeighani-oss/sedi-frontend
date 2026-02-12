/// Lifestyle: GET /lifestyle/context, POST /lifestyle/update, GET /lifestyle/summary (Stage 17.2).
/// See: frontend/docs/FRONTEND_BACKEND_ALIGNMENT.md
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../dto/lifestyle_data_create.dart';
import '../dto/lifestyle_summary_response.dart';

class LifestyleRepository {
  final ApiClient _client;

  LifestyleRepository({String? baseUrl, ApiClient? apiClient})
      : _client = apiClient ?? ApiClient(baseUrl: baseUrl ?? AppConfig.baseUrl);

  Map<String, String> _userQuery(int userId) => {'user_id': userId.toString()};

  /// GET /lifestyle/summary — fetch lifestyle summary for user (Stage 17.2).
  Future<ApiResponse<LifestyleSummaryResponse?>> fetchLifestyleSummary({
    required int userId,
    String? lang,
  }) async {
    final params = _userQuery(userId);
    if (lang != null && lang.isNotEmpty) params['lang'] = lang;
    return _client.get<LifestyleSummaryResponse?>(
      '/lifestyle/summary',
      queryParams: params,
      parser: (v) => LifestyleSummaryResponse.fromApiData(v),
    );
  }

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
