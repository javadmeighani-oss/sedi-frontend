import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';

/// Exact state of the gadget's heart-rate data (`data_status` of `GET /lifestyle/health-hr`).
class HrDataStatus {
  /// 'receiving' | 'quiet' | 'stale' | 'never'
  final String state;
  final int? minutesSinceLast;
  final int todayCount;
  final String? firstAt;
  final String? lastAt;
  final int? longestGapMinutes;
  final int weekDaysWithData;
  final int weekAvgPerDay;

  const HrDataStatus({
    this.state = 'never',
    this.minutesSinceLast,
    this.todayCount = 0,
    this.firstAt,
    this.lastAt,
    this.longestGapMinutes,
    this.weekDaysWithData = 0,
    this.weekAvgPerDay = 0,
  });

  factory HrDataStatus.fromJson(Object? raw) {
    if (raw is! Map) return const HrDataStatus();
    final today = raw['today'] is Map ? Map<String, dynamic>.from(raw['today'] as Map) : const <String, dynamic>{};
    final week = raw['week'] is Map ? Map<String, dynamic>.from(raw['week'] as Map) : const <String, dynamic>{};
    int? i(Object? v) => v == null ? null : int.tryParse('$v');
    return HrDataStatus(
      state: raw['state']?.toString() ?? 'never',
      minutesSinceLast: i(raw['minutes_since_last']),
      todayCount: i(today['count']) ?? 0,
      firstAt: today['first_at']?.toString(),
      lastAt: today['last_at']?.toString(),
      longestGapMinutes: i(today['longest_gap_minutes']),
      weekDaysWithData: i(week['days_with_data']) ?? 0,
      weekAvgPerDay: i(week['avg_per_day']) ?? 0,
    );
  }
}

/// Range summary (sample-weighted average, lowest and highest reading).
class HrSummary {
  final int avg;
  final int min;
  final int max;

  const HrSummary({required this.avg, required this.min, required this.max});

  static HrSummary? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final avg = int.tryParse('${raw['avg']}');
    final min = int.tryParse('${raw['min']}');
    final max = int.tryParse('${raw['max']}');
    if (avg == null || min == null || max == null) return null;
    return HrSummary(avg: avg, min: min, max: max);
  }
}

class LifestyleHealthHrDto {
  /// Authoritative gadget status only when [hrStatusSource] is DEVICE_REPORTED.
  final String? hrStatus;
  final String? hrStatusSource;
  final String? hrStatusObservedAt;
  /// Legacy MAD compact — never treat as DEVICE_REPORTED authority.
  final String? hrStabilityCompact;
  final double? latestValue;
  final String? latestReceivedAt;
  final String rangeKey;
  final List<Map<String, dynamic>> history;
  final String? availableFrom;
  final String? availableTo;

  /// P10: range summary, a plain 'steady' | 'up' | 'down' | 'insufficient' observation, and the data status.
  final HrSummary? summary;
  final String trend;
  final HrDataStatus dataStatus;

  const LifestyleHealthHrDto({
    this.hrStatus,
    this.hrStatusSource,
    this.hrStatusObservedAt,
    this.hrStabilityCompact,
    this.latestValue,
    this.latestReceivedAt,
    required this.rangeKey,
    this.history = const [],
    this.availableFrom,
    this.availableTo,
    this.summary,
    this.trend = 'insufficient',
    this.dataStatus = const HrDataStatus(),
  });

  static const _deviceStatuses = {'STABLE', 'UNSTABLE'};

  /// True only for authoritative DEVICE_REPORTED STABLE|UNSTABLE.
  bool get isDeviceReportedStatus {
    final source = (hrStatusSource ?? '').trim().toUpperCase();
    final status = (hrStatus ?? '').trim().toUpperCase();
    return source == 'DEVICE_REPORTED' && _deviceStatuses.contains(status);
  }

  factory LifestyleHealthHrDto.fromJson(Map<String, dynamic> json) {
    final raw = json['history'];
    final hist = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) hist.add(Map<String, dynamic>.from(e));
      }
    }
    final statusRaw = json['hr_status']?.toString().trim();
    final status =
        (statusRaw == null || statusRaw.isEmpty) ? null : statusRaw;
    return LifestyleHealthHrDto(
      hrStatus: status,
      hrStatusSource: json['hr_status_source']?.toString() ??
          json['status_source']?.toString() ??
          json['status_provenance']?.toString(),
      hrStatusObservedAt: json['hr_status_observed_at']?.toString(),
      hrStabilityCompact: json['hr_stability_compact']?.toString(),
      latestValue: (json['latest_value'] is num)
          ? (json['latest_value'] as num).toDouble()
          : double.tryParse('${json['latest_value']}'),
      latestReceivedAt: json['latest_received_at']?.toString(),
      rangeKey: json['range_key']?.toString() ?? '7d',
      history: hist,
      availableFrom: json['available_from']?.toString(),
      availableTo: json['available_to']?.toString(),
      summary: HrSummary.fromJson(json['summary']),
      trend: json['trend']?.toString() ?? 'insufficient',
      dataStatus: HrDataStatus.fromJson(json['data_status']),
    );
  }
}

class LifestyleHealthService {
  final ApiClient _api;
  LifestyleHealthService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  Future<ApiResponse<LifestyleHealthHrDto>> fetchHr({String rangeKey = '7d'}) {
    return _api.get<LifestyleHealthHrDto>(
      '/lifestyle/health-hr',
      queryParams: {'range_key': rangeKey},
      parser: (data) {
        if (data is Map) {
          return LifestyleHealthHrDto.fromJson(Map<String, dynamic>.from(data));
        }
        return null;
      },
    );
  }
}
