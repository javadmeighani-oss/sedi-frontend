import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../data/dto/lifestyle/lifestyle_weekly_plan_dto.dart';

/// Shared read-only transport for `GET /lifestyle/weekly-plan`.
/// Used by Nutrition and Exercise presentation (one service only).
class LifestyleWeeklyPlanService {
  final ApiClient _api;

  LifestyleWeeklyPlanService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  /// End-of-day/week review of one plan action: outcome done | skipped (+ bounded reason).
  Future<ApiResponse<Map<String, dynamic>?>> reviewAction(
    int actionId,
    String outcome, {
    String? reason,
  }) {
    return _api.post<Map<String, dynamic>?>(
      '/lifestyle/actions/$actionId/review',
      body: <String, dynamic>{
        'outcome': outcome,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
      parser: (v) => v == null ? null : Map<String, dynamic>.from(v as Map),
    );
  }

  /// The user moves one plan item to [localTime] (HH:MM); Sedi's reminder for it follows the new time.
  Future<ApiResponse<void>> moveAction(int actionId, String localTime) {
    return _api.patch<void>(
      '/lifestyle/actions/$actionId',
      body: <String, dynamic>{'local_time': localTime},
      parser: (_) => null,
    );
  }

  /// The user takes one plan item out of this week.
  Future<ApiResponse<void>> removeAction(int actionId) {
    return _api.delete<void>('/lifestyle/actions/$actionId', parser: (_) => null);
  }

  Future<ApiResponse<LifestyleWeeklyPlanDto>> fetchWeeklyPlan() {
    return _api.get<LifestyleWeeklyPlanDto>(
      '/lifestyle/weekly-plan',
      parser: (data) {
        if (data is Map) {
          return LifestyleWeeklyPlanDto.fromJson(
            Map<String, dynamic>.from(data),
          );
        }
        return null;
      },
    );
  }
}
