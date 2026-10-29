import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../data/dto/lifestyle/lifestyle_weekly_plan_dto.dart';
import '../../data/dto/lifestyle/plan_alternative.dart';
import '../../data/dto/lifestyle/plan_settings_dto.dart';

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

  /// Other items Sedi's rules would accept for this slot (allergies, dislikes and limits already applied).
  Future<ApiResponse<List<PlanAlternative>>> fetchAlternatives(int actionId) {
    return _api.get<List<PlanAlternative>>(
      '/lifestyle/actions/$actionId/alternatives',
      parser: (data) {
        final raw = data is Map ? data['alternatives'] : null;
        if (raw is! List) return <PlanAlternative>[];
        return [
          for (final e in raw)
            if (e is Map)
              PlanAlternative(
                itemId: '${e['item_id'] ?? ''}',
                title: '${e['title'] ?? ''}',
                detail: '${e['detail'] ?? ''}',
              ),
        ];
      },
    );
  }

  /// The user swaps the item for one of the alternatives.
  Future<ApiResponse<void>> replaceAction(int actionId, String itemId) {
    return _api.post<void>(
      '/lifestyle/actions/$actionId/replace',
      body: <String, dynamic>{'item_id': itemId},
      parser: (_) => null,
    );
  }

  /// The user corrects the item's own words / duration.
  Future<ApiResponse<void>> editAction(int actionId, {String? title, String? note, int? durationMinutes}) {
    return _api.patch<void>(
      '/lifestyle/actions/$actionId',
      body: <String, dynamic>{
        if (title != null) 'title': title,
        if (note != null) 'note': note,
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
      },
      parser: (_) => null,
    );
  }

  /// The user takes one plan item out of this week.
  Future<ApiResponse<void>> removeAction(int actionId) {
    return _api.delete<void>('/lifestyle/actions/$actionId', parser: (_) => null);
  }

  /// Reminder days / lead and the weekly-review day of one plan (`nutrition` | `exercise`).
  Future<ApiResponse<PlanSettingsDto>> fetchPlanSettings(String domain) {
    return _api.get<PlanSettingsDto>(
      '/lifestyle/plan-settings',
      queryParams: <String, String>{'domain': domain},
      parser: (data) {
        final raw = data is Map ? data['settings'] : null;
        return raw is Map ? PlanSettingsDto.fromJson(Map<String, dynamic>.from(raw)) : null;
      },
    );
  }

  Future<ApiResponse<PlanSettingsDto>> savePlanSettings(String domain, PlanSettingsDto settings) {
    return _api.put<PlanSettingsDto>(
      '/lifestyle/plan-settings',
      queryParams: <String, String>{'domain': domain},
      body: settings.toJson(),
      parser: (data) {
        final raw = data is Map ? data['settings'] : null;
        return raw is Map ? PlanSettingsDto.fromJson(Map<String, dynamic>.from(raw)) : null;
      },
    );
  }

  /// Build (or adjust) this week's plan from the setup sheet - the same composer chat uses.
  Future<ApiResponse<PlanBuildResultDto>> buildPlan(PlanSetupInput input) {
    return _api.post<PlanBuildResultDto>(
      '/lifestyle/plan/build',
      body: input.toJson(),
      parser: (data) => data is Map ? PlanBuildResultDto.fromJson(Map<String, dynamic>.from(data)) : null,
    );
  }

  /// The motivation panel: this week's sessions, day marks, streak and Sedi's line.
  Future<ApiResponse<PlanProgressDto>> fetchPlanProgress(String domain) {
    return _api.get<PlanProgressDto>(
      '/lifestyle/plan-progress',
      queryParams: <String, String>{'domain': domain},
      parser: (data) => data is Map ? PlanProgressDto.fromJson(Map<String, dynamic>.from(data)) : null,
    );
  }

  /// How the current week went (from what the user marked).
  Future<ApiResponse<WeeklyReviewDto>> fetchWeeklyReview(String domain) {
    return _api.get<WeeklyReviewDto>(
      '/lifestyle/weekly-review',
      queryParams: <String, String>{'domain': domain},
      parser: (data) => data is Map ? WeeklyReviewDto.fromJson(Map<String, dynamic>.from(data)) : null,
    );
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
