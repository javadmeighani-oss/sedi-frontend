import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';

/// User Knowledge API: PUT /user/knowledge (profile baseline).
/// Used for best-effort sync of preferred name, language, and goals after onboarding.
class UserKnowledgeRepository {
  final ApiClient _client;

  UserKnowledgeRepository({String? baseUrl, ApiClient? apiClient})
      : _client = apiClient ?? ApiClient(baseUrl: baseUrl ?? AppConfig.baseUrl);

  /// PUT /user/knowledge — upsert profile knowledge (display_name, language, goals_json).
  /// Best-effort: call from onboarding; do not block on failure.
  Future<ApiResponse<Map<String, dynamic>>> upsertKnowledge({
    required int userId,
    String? displayName,
    String? language,
    String? goalsJson,
  }) async {
    final body = <String, dynamic>{
      'user_id': userId,
    };
    if (displayName != null) body['display_name'] = displayName;
    if (language != null) body['language'] = language;
    if (goalsJson != null) body['goals_json'] = goalsJson;

    return _client.putRaw('/user/knowledge', body: body);
  }
}
