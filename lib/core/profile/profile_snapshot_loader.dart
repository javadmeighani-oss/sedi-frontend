import 'package:flutter/foundation.dart';

import '../../data/dto/auth/me_profile.dart';
import '../auth/auth_profile_service.dart';
import '../memory/memory_consent_service.dart';
import '../network/api_client.dart';
import 'profile_snapshot_cache.dart';

/// The result of one profile read: what could be read, and the profile error text when it could not.
class ProfileSnapshotResult {
  const ProfileSnapshotResult({this.me, this.meError});

  final MeProfileDto? me;
  final String? meError;
}

/// Reads the profile, the summary sentence and the memory switch TOGETHER (they used to load one after another) and
/// writes them into [ProfileSnapshotCache]. A3 starts it in the background, so the profile page is already filled when
/// it opens; the page calls it again to refresh silently. Fail-open: a failed read keeps what the cache already holds.
class ProfileSnapshotLoader {
  ProfileSnapshotLoader._();

  static const String summaryPath = '/auth/me/profile-summary';

  static Future<ProfileSnapshotResult>? _inFlight;

  /// [force] = start a new read even if one is in progress (after the user changed something).
  static Future<ProfileSnapshotResult> refresh({
    required String Function(Object? data) summaryParser,
    bool force = false,
    AuthProfileService? profile,
    ApiClient? api,
    MemoryConsentService? memory,
  }) {
    if (!force && _inFlight != null) return _inFlight!;
    final run = _run(
      summaryParser: summaryParser,
      profile: profile ?? AuthProfileService(),
      api: api ?? ApiClient(),
      memory: memory ?? MemoryConsentService(),
    );
    _inFlight = run;
    run.whenComplete(() {
      if (identical(_inFlight, run)) _inFlight = null;
    });
    return run;
  }

  static Future<ProfileSnapshotResult> _run({
    required String Function(Object? data) summaryParser,
    required AuthProfileService profile,
    required ApiClient api,
    required MemoryConsentService memory,
  }) async {
    try {
      // All three requests start now; none waits for another.
      final meF = profile.fetchMe(recoverSessionOn401: true);
      final summaryF = api.get<String>(summaryPath, parser: summaryParser);
      final memoryF = memory.fetchStatus();
      final meRes = await meF;
      final summaryRes = await summaryF;
      final memoryRes = await memoryF;

      MeProfileDto? me;
      String? error;
      if (meRes.ok && meRes.data != null) {
        me = meRes.data;
        ProfileSnapshotCache.putMe(me!);
      } else {
        error = meRes.errorMessage;
      }
      if (summaryRes.ok && summaryRes.data != null) {
        ProfileSnapshotCache.putSummary(summaryRes.data!);
      }
      if (memoryRes.ok && memoryRes.data != null) {
        ProfileSnapshotCache.putMemory(memoryRes.data!);
      }
      return ProfileSnapshotResult(me: me, meError: error);
    } catch (e) {
      if (kDebugMode) debugPrint('[ProfileSnapshotLoader] refresh failed: $e');
      return const ProfileSnapshotResult();
    }
  }

  @visibleForTesting
  static void reset() => _inFlight = null;
}
