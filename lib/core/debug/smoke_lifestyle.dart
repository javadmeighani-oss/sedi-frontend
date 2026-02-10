/// Debug helper: POST /lifestyle/update, GET /lifestyle/context.
/// Guarded — call explicitly (e.g. from a debug menu); not executed automatically.
import '../../data/dto/lifestyle_data_create.dart';
import '../../data/repositories/lifestyle_repository.dart';
import '../utils/user_profile_manager.dart';

/// Posts sample lifestyle data for the current user (from UserProfileManager).
/// Use only in debug builds or when explicitly triggered.
/// Returns result summary string for logging.
Future<String> smokeLifestyleUpdate() async {
  final profile = await UserProfileManager.loadProfile();
  final userId = profile.userId;
  if (userId == null) {
    return '[smoke_lifestyle] No user_id in profile; skip POST /lifestyle/update';
  }
  final repo = LifestyleRepository();
  final req = LifestyleDataCreate(
    userId: userId,
    sleepHours: 7.5,
    steps: 5000,
    calories: 2000,
    stressLevel: 2,
  );
  final response = await repo.updateLifestyle(req);
  if (response.ok) {
    return '[smoke_lifestyle] OK update';
  }
  return '[smoke_lifestyle] FAIL update ${response.error?.message ?? "unknown"}';
}

/// Fetches lifestyle context for the current user.
/// Use only in debug builds or when explicitly triggered.
/// Returns result summary string for logging.
Future<String> smokeLifestyleContext() async {
  final profile = await UserProfileManager.loadProfile();
  final userId = profile.userId;
  if (userId == null) {
    return '[smoke_lifestyle] No user_id in profile; skip GET /lifestyle/context';
  }
  final repo = LifestyleRepository();
  final response = await repo.fetchContext(userId);
  if (response.ok && response.data != null) {
    return '[smoke_lifestyle] OK context keys=${response.data!.keys.join(",")}';
  }
  return '[smoke_lifestyle] FAIL context ${response.error?.message ?? "no data"}';
}
