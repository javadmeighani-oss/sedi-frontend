/// Local cache for latest vitals (SharedPreferences). Key: last_vitals_<userId>.
/// Also exposes validation helpers for form inputs (HR, SpO2, Temp).
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const String _keyPrefix = 'last_vitals_';

/// In-memory model for cached vitals (matches stored JSON).
class CachedVitals {
  final double? heartRate;
  final double? temperature;
  final double? spo2;
  final DateTime? createdAt;

  const CachedVitals({
    this.heartRate,
    this.temperature,
    this.spo2,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      if (heartRate != null) 'heart_rate': heartRate,
      if (temperature != null) 'temperature': temperature,
      if (spo2 != null) 'spo2': spo2,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  static CachedVitals? fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return null;
    double? heartRate;
    if (json['heart_rate'] != null) {
      heartRate = (json['heart_rate'] is num) ? (json['heart_rate'] as num).toDouble() : double.tryParse(json['heart_rate'].toString());
    }
    double? temperature;
    if (json['temperature'] != null) {
      temperature = (json['temperature'] is num) ? (json['temperature'] as num).toDouble() : double.tryParse(json['temperature'].toString());
    }
    double? spo2;
    if (json['spo2'] != null) {
      spo2 = (json['spo2'] is num) ? (json['spo2'] as num).toDouble() : double.tryParse(json['spo2'].toString());
    }
    DateTime? createdAt;
    if (json['created_at'] != null) {
      createdAt = DateTime.tryParse(json['created_at'].toString());
    }
    return CachedVitals(heartRate: heartRate, temperature: temperature, spo2: spo2, createdAt: createdAt);
  }
}

/// Load cached vitals for user. Returns null if missing or invalid.
Future<CachedVitals?> loadLastVitals(int userId) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('$_keyPrefix$userId');
  if (raw == null || raw.isEmpty) return null;
  try {
    final decoded = jsonDecode(raw) as Map<String, dynamic>?;
    return CachedVitals.fromJson(decoded);
  } catch (_) {
    return null;
  }
}

/// Save vitals to cache for user.
Future<bool> saveLastVitals(int userId, CachedVitals vitals) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.setString('$_keyPrefix$userId', jsonEncode(vitals.toJson()));
}

// --- Validation (ranges: HR 30-220, SpO2 50-100, Temp 30-45). Returns null if valid, error message otherwise.

const int _hrMin = 30, _hrMax = 220;
const int _spo2Min = 50, _spo2Max = 100;
const double _tempMin = 30.0, _tempMax = 45.0;

String? validateHeartRate(int? value) {
  if (value == null) return null; // optional in display; required at submit is enforced elsewhere
  if (value < _hrMin || value > _hrMax) return 'Heart rate must be $_hrMin–$_hrMax';
  return null;
}

String? validateSpO2(int? value) {
  if (value == null) return null;
  if (value < _spo2Min || value > _spo2Max) return 'SpO2 must be $_spo2Min–$_spo2Max';
  return null;
}

String? validateTemperature(double? value) {
  if (value == null) return null;
  if (value < _tempMin || value > _tempMax) return 'Temperature must be $_tempMin–$_tempMax';
  return null;
}

/// VitalsCache: namespace for load/save so callers can use VitalsCache.loadLastVitals(userId).
class VitalsCache {
  VitalsCache._();
  static Future<CachedVitals?> getLastVitals(int userId) => loadLastVitals(userId);
  static Future<bool> setLastVitals(int userId, CachedVitals v) => saveLastVitals(userId, v);
}
