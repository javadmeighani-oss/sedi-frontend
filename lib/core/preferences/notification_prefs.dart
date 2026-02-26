import 'package:shared_preferences/shared_preferences.dart';

/// V1 notification settings persisted locally (SharedPreferences).
/// Defaults applied when unset; safe to call before init.
const String kNotificationPrefsPrefix = 'notif_v1_';
const String _keyChannelPrefix = '${kNotificationPrefsPrefix}channel_';
const String _keyQuietStart = '${kNotificationPrefsPrefix}quiet_start';
const String _keyQuietEnd = '${kNotificationPrefsPrefix}quiet_end';
const String _keyEngagementLevel = '${kNotificationPrefsPrefix}engagement';
const String _keySoundKey = '${kNotificationPrefsPrefix}sound';

const String kDefaultQuietStart = '22:30';
const String kDefaultQuietEnd = '07:30';
const String kDefaultEngagementLevel = 'normal';
const String kDefaultSoundKey = 'default';

const List<String> kNotificationChannels = [
  'companion',
  'health_alert',
  'medication',
  'appointment',
  'system',
];

const List<String> kEngagementLevels = ['low', 'normal', 'high'];

const List<String> kSoundKeys = ['default', 'soft', 'chime', 'pulse', 'silent'];

class NotificationPrefs {
  static Future<SharedPreferences> _getPrefs() async {
    return SharedPreferences.getInstance();
  }

  static String _channelKey(String channel) => '$_keyChannelPrefix$channel';

  /// Whether the channel is enabled. Default true if unset.
  static Future<bool> getChannelEnabled(String channel) async {
    try {
      final prefs = await _getPrefs();
      return prefs.getBool(_channelKey(channel)) ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> setChannelEnabled(String channel, bool enabled) async {
    try {
      final prefs = await _getPrefs();
      return prefs.setBool(_channelKey(channel), enabled);
    } catch (_) {
      return false;
    }
  }

  /// Quiet hours start (HH:mm). Default 22:30.
  static Future<String> getQuietHoursStart() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(_keyQuietStart) ?? kDefaultQuietStart;
    } catch (_) {
      return kDefaultQuietStart;
    }
  }

  static Future<bool> setQuietHoursStart(String value) async {
    try {
      final prefs = await _getPrefs();
      return prefs.setString(_keyQuietStart, value);
    } catch (_) {
      return false;
    }
  }

  /// Quiet hours end (HH:mm). Default 07:30.
  static Future<String> getQuietHoursEnd() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(_keyQuietEnd) ?? kDefaultQuietEnd;
    } catch (_) {
      return kDefaultQuietEnd;
    }
  }

  static Future<bool> setQuietHoursEnd(String value) async {
    try {
      final prefs = await _getPrefs();
      return prefs.setString(_keyQuietEnd, value);
    } catch (_) {
      return false;
    }
  }

  /// Engagement level for companion: low | normal | high. Default normal.
  static Future<String> getEngagementLevel() async {
    try {
      final prefs = await _getPrefs();
      final v = prefs.getString(_keyEngagementLevel) ?? kDefaultEngagementLevel;
      return kEngagementLevels.contains(v) ? v : kDefaultEngagementLevel;
    } catch (_) {
      return kDefaultEngagementLevel;
    }
  }

  static Future<bool> setEngagementLevel(String value) async {
    try {
      final prefs = await _getPrefs();
      return prefs.setString(_keyEngagementLevel, value);
    } catch (_) {
      return false;
    }
  }

  /// Sound key: default | soft | chime | pulse | silent. Default default.
  static Future<String> getSoundKey() async {
    try {
      final prefs = await _getPrefs();
      final v = prefs.getString(_keySoundKey) ?? kDefaultSoundKey;
      return kSoundKeys.contains(v) ? v : kDefaultSoundKey;
    } catch (_) {
      return kDefaultSoundKey;
    }
  }

  static Future<bool> setSoundKey(String value) async {
    try {
      final prefs = await _getPrefs();
      return prefs.setString(_keySoundKey, value);
    } catch (_) {
      return false;
    }
  }
}
