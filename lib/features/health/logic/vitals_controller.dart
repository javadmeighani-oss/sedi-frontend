/// Minimal vitals logic: load cache, optional fetch from server, submit via HealthRepository.
import '../../../core/utils/user_profile_manager.dart';
import '../../../data/dto/health_data_create.dart';
import '../../../data/repositories/health_repository.dart';
import 'vitals_cache.dart';
import 'vitals_history.dart';

/// Source of displayed last vitals: from server or local cache.
const String kSourceServer = 'server';
const String kSourceCache = 'cache';

class VitalsController {
  final HealthRepository _repo = HealthRepository();

  /// True while load() is running (cache + fetch).
  bool isLoading = false;

  /// True while submit() is running (prevents duplicate submit).
  bool isSubmitting = false;

  /// Last vitals to display (from cache or server after load()).
  CachedVitals? lastVitals;

  /// 'server' if lastVitals came from fetch; 'cache' if from local only.
  String lastSource = kSourceCache;

  /// Read-only: recent 7-day history (newest first). Updated after load().
  List<CachedVitals> recentHistory = [];

  /// 7-day average heart rate (rounded); null if no data. Updated after load().
  int? avgHeartRate7d;

  /// Number of records in 7-day window. Updated after load().
  int countRecords7d = 0;

  /// Load last vitals: (1) load from cache, (2) try fetch from server; on success update cache and set lastSource = server.
  /// On 404/405/network failure we keep cache and do not surface an error.
  Future<void> load() async {
    isLoading = true;
    try {
      final profile = await UserProfileManager.loadProfile();
      final userId = profile.userId;
      if (userId == null) return;

      final cached = await loadLastVitals(userId);
      lastVitals = cached;
      lastSource = kSourceCache;

      final response = await _repo.fetchLatestHealthData(userId);
      if (response.ok && response.data != null) {
        final d = response.data!;
        lastVitals = CachedVitals(
          heartRate: d.heartRate,
          temperature: d.temperature,
          spo2: d.spo2,
          createdAt: d.createdAt ?? DateTime.now(),
        );
        await saveLastVitals(userId, lastVitals!);
        lastSource = kSourceServer;
      }
      await _refreshHistory(userId);
    } finally {
      isLoading = false;
    }
  }

  Future<void> _refreshHistory(int userId) async {
    if (lastVitals != null) {
      await appendVitalsHistoryEntry(userId, lastVitals!);
    }
    final list = await loadVitalsHistory(userId);
    recentHistory = list;
    final stats = computeStats(list);
    avgHeartRate7d = stats.avgHeartRate7d;
    countRecords7d = stats.countRecords7d;
  }

  /// Load last vitals from local cache only (for backward compatibility / refresh after submit).
  Future<CachedVitals?> loadCachedVitals() async {
    final profile = await UserProfileManager.loadProfile();
    final userId = profile.userId;
    if (userId == null) return null;
    return loadLastVitals(userId);
  }

  /// Submit vitals. heartRate required (int 30-220); spo2 and temperature optional.
  /// Returns (true, null) on success, (false, errorMessage) on failure.
  /// On success, updates local cache with response data or submitted values.
  Future<(bool success, String? error)> submit({
    required int heartRate,
    int? spo2,
    double? temperature,
  }) async {
    if (isLoading) return (false, 'Please wait.');
    if (isSubmitting) return (false, 'Please wait.');
    isSubmitting = true;
    try {
      final profile = await UserProfileManager.loadProfile();
      final userId = profile.userId;
      if (userId == null) return (false, 'User not found');

      final hrError = validateHeartRate(heartRate);
      if (hrError != null) return (false, hrError);
      if (spo2 != null) {
        final e = validateSpO2(spo2);
        if (e != null) return (false, e);
      }
      if (temperature != null) {
        final e = validateTemperature(temperature);
        if (e != null) return (false, e);
      }

      final req = HealthDataCreate(
        userId: userId,
        heartRate: heartRate.toDouble(),
        spo2: spo2 != null ? spo2.toDouble() : null,
        temperature: temperature,
      );
      final response = await _repo.addHealthData(req);

      if (!response.ok) {
        final msg = response.errorMessage;
        final friendly = _isNetworkError(msg) ? 'Connection issue. Try again.' : msg;
        return (false, friendly);
      }

      final data = response.data;
      CachedVitals saved;
      if (data != null && (data.heartRate != null || data.temperature != null || data.spo2 != null)) {
        saved = CachedVitals(
          heartRate: data.heartRate,
          temperature: data.temperature,
          spo2: data.spo2,
          createdAt: data.createdAt ?? DateTime.now(),
        );
        await saveLastVitals(userId, saved);
      } else {
        saved = CachedVitals(
          heartRate: heartRate.toDouble(),
          temperature: temperature,
          spo2: spo2 != null ? spo2.toDouble() : null,
          createdAt: DateTime.now(),
        );
        await saveLastVitals(userId, saved);
      }
      await appendVitalsHistoryEntry(userId, saved);
      return (true, null);
    } finally {
      isSubmitting = false;
    }
  }

  static bool _isNetworkError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('connection') ||
        lower.contains('socket') ||
        lower.contains('timeout') ||
        lower.contains('network') ||
        lower.contains('unreachable') ||
        lower.contains('failed host lookup');
  }
}
