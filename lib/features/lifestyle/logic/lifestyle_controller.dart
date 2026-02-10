/// Lifestyle context load + update. Uses LifestyleRepository; single responsibility.
import '../../../core/utils/user_profile_manager.dart';
import '../../../data/dto/lifestyle_data_create.dart';
import '../../../data/dto/lifestyle_context_response.dart';
import '../../../data/repositories/lifestyle_repository.dart';
import 'lifestyle_validation.dart';

class LifestyleController {
  final LifestyleRepository _repo = LifestyleRepository();

  bool isLoading = false;
  bool isSubmitting = false;
  Map<String, dynamic>? contextMap;
  String? errorMessage;

  /// Load context for current user. Sets contextMap on success.
  Future<void> loadContext() async {
    final profile = await UserProfileManager.loadProfile();
    final userId = profile.userId;
    if (userId == null) {
      contextMap = null;
      errorMessage = 'User not found';
      return;
    }
    isLoading = true;
    errorMessage = null;
    try {
      final response = await _repo.fetchContext(userId);
      if (response.ok && response.data != null) {
        contextMap = response.data;
        errorMessage = null;
      } else {
        errorMessage = response.errorMessage;
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
    }
  }

  /// Submit lifestyle update. Validates ranges; on success reloads context.
  Future<bool> submitUpdate({
    double? sleepHours,
    int? steps,
    int? calories,
    int? stressLevel,
  }) async {
    if (sleepHours != null && validateSleepHours(sleepHours) != null) return false;
    if (steps != null && validateSteps(steps) != null) return false;
    if (calories != null && validateCalories(calories) != null) return false;
    if (stressLevel != null && validateStressLevel(stressLevel) != null) return false;

    final profile = await UserProfileManager.loadProfile();
    final userId = profile.userId;
    if (userId == null) {
      errorMessage = 'User not found';
      return false;
    }
    isSubmitting = true;
    errorMessage = null;
    try {
      final req = LifestyleDataCreate(
        userId: userId,
        sleepHours: sleepHours,
        steps: steps,
        calories: calories,
        stressLevel: stressLevel,
      );
      final response = await _repo.updateLifestyle(req);
      if (!response.ok) {
        errorMessage = response.errorMessage;
        return false;
      }
      await loadContext();
      return true;
    } finally {
      isSubmitting = false;
    }
  }

  /// Parsed context for display (optional).
  LifestyleContextResponse? get parsedContext =>
      contextMap != null ? LifestyleContextResponse.fromJson(contextMap) : null;
}
