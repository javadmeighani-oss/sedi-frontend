/// Debug helper: POST sample health data to /health/add.
/// Guarded — call explicitly (e.g. from a debug menu); not executed automatically.
import '../../data/dto/health_data_create.dart';
import '../../data/repositories/health_repository.dart';
import '../utils/user_profile_manager.dart';

/// Posts a sample health payload for the current user (from UserProfileManager).
/// Use only in debug builds or when explicitly triggered.
/// Returns result summary string for logging.
Future<String> smokeHealthAdd() async {
  final profile = await UserProfileManager.loadProfile();
  final userId = profile.userId;
  if (userId == null) {
    return '[smoke_health] No user_id in profile; skip POST /health/add';
  }
  final repo = HealthRepository();
  final req = HealthDataCreate(
    userId: userId,
    heartRate: 72.0,
    temperature: 36.6,
    spo2: 98.0,
  );
  final response = await repo.addHealthData(req);
  if (response.ok && response.data != null) {
    final d = response.data!;
    return '[smoke_health] OK health_id=${d.id} user_id=${d.userId} message=${d.message}';
  }
  return '[smoke_health] FAIL ${response.error?.message ?? "unknown"}';
}
