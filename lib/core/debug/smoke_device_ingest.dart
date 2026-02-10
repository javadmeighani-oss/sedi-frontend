/// Debug helper: POST sample device ingest event.
/// Guarded — call explicitly; not executed automatically.
import '../../data/dto/device_ingest_request.dart';
import '../../data/repositories/device_repository.dart';
import '../utils/user_profile_manager.dart';

/// Posts a sample device event (heart_rate) for the current user (from UserProfileManager).
/// Use only in debug builds or when explicitly triggered.
/// Returns result summary string for logging.
Future<String> smokeDeviceIngest() async {
  final profile = await UserProfileManager.loadProfile();
  final userId = profile.userId;
  if (userId == null) {
    return '[smoke_device_ingest] No user_id in profile; skip';
  }
  final repo = DeviceRepository();
  final req = DeviceIngestRequest(
    userId: userId,
    deviceId: 'SediDebug001',
    eventType: 'heart_rate',
    payload: {'bpm': 72, 'quality': 'good'},
    recordedAt: DateTime.now().toUtc(),
  );
  final response = await repo.ingest(req);
  if (response.ok && response.data != null) {
    final d = response.data!;
    return '[smoke_device_ingest] OK event_id=${d.eventId} dedupe_key=${d.dedupeKey}';
  }
  return '[smoke_device_ingest] FAIL ${response.error?.message ?? "unknown"}';
}
