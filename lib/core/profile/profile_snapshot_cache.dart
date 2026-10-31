import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/dto/auth/me_profile.dart';
import '../memory/memory_consent_status.dart';

/// What the profile page shows the moment it opens (Javad 2026-10-31: the profile had a load time; it must have none).
///
/// A1 already reads `/auth/me` for the session check, so the profile data costs nothing extra; A3 asks for the summary
/// and the memory switch in the background. The page paints this cache first and refreshes silently; no spinner.
///
/// Persisted: the profile fields (the app already keeps them on the device in [UserProfileManager]) and the memory
/// switch, so even the first open after a restart is instant. NOT persisted: the summary sentence (it describes the
/// user's health picture; it lives in memory only and arrives from A3's background read).
class ProfileSnapshotCache {
  ProfileSnapshotCache._();

  static const String _prefsKey = 'sedi.profile_snapshot.v1';

  static MeProfileDto? _me;
  static String _summary = '';
  static MemoryConsentStatus? _memory;

  static MeProfileDto? get me => _me;
  static String get summary => _summary;
  static MemoryConsentStatus? get memory => _memory;

  /// Fills the cache from the device copy (call early; never overwrites anything already fresher in memory).
  static Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw);
      if (map is! Map) return;
      if (_me == null && map['me'] is Map) {
        final me = MeProfileDto.fromJson(Map<String, dynamic>.from(map['me'] as Map));
        if (me.userId > 0) _me = me;
      }
      if (_memory == null && map['memory'] is Map) {
        final m = Map<String, dynamic>.from(map['memory'] as Map);
        _memory = MemoryConsentStatus(
          granted: m['granted'] == true,
          status: (m['status'] ?? '').toString(),
          writeAllowed: m['write'] == true,
          readAllowed: m['read'] == true,
          forgetAllowed: m['forget'] == true,
          policyVersion: m['policy']?.toString(),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ProfileSnapshotCache] restore failed: $e');
    }
  }

  static void putMe(MeProfileDto me) {
    _me = me;
    _persist();
  }

  static void putSummary(String summary) {
    _summary = summary;
  }

  static void putMemory(MemoryConsentStatus status) {
    _memory = status;
    _persist();
  }

  /// Logout / invalid session: nothing of the user stays behind.
  static Future<void> clear() async {
    _me = null;
    _summary = '';
    _memory = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
  }

  static void _persist() {
    final me = _me;
    final memory = _memory;
    final payload = jsonEncode({
      if (me != null) 'me': me.toJson(),
      if (memory != null)
        'memory': {
          'granted': memory.granted,
          'status': memory.status,
          'write': memory.writeAllowed,
          'read': memory.readAllowed,
          'forget': memory.forgetAllowed,
          if (memory.policyVersion != null) 'policy': memory.policyVersion,
        },
    });
    SharedPreferences.getInstance().then((prefs) => prefs.setString(_prefsKey, payload)).catchError((Object _) => false);
  }

  @visibleForTesting
  static void reset() {
    _me = null;
    _summary = '';
    _memory = null;
  }
}
