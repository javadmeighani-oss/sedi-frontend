/// Typed contract for `GET /lifestyle/weekly-plan` (backend I8 projection).
class LifestyleWeeklyPlanDto {
  final String? cycleStart;
  final String? cycleEnd;
  final String? timezone;
  final String state;
  final bool reviewDue;
  final String? todayLocal;
  final LifestyleWeeklyAdherenceDto? adherence;
  final List<LifestyleWeeklyDayDto> days;

  const LifestyleWeeklyPlanDto({
    this.cycleStart,
    this.cycleEnd,
    this.timezone,
    required this.state,
    this.reviewDue = false,
    this.todayLocal,
    this.adherence,
    this.days = const [],
  });

  factory LifestyleWeeklyPlanDto.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'];
    final days = <LifestyleWeeklyDayDto>[];
    if (rawDays is List) {
      for (final e in rawDays) {
        if (e is Map) {
          days.add(
            LifestyleWeeklyDayDto.fromJson(Map<String, dynamic>.from(e)),
          );
        }
      }
    }
    return LifestyleWeeklyPlanDto(
      cycleStart: json['cycle_start']?.toString(),
      cycleEnd: json['cycle_end']?.toString(),
      timezone: json['timezone']?.toString(),
      state: (json['state']?.toString() ?? 'unavailable').toLowerCase(),
      reviewDue: json['review_due'] == true,
      todayLocal: json['today_local']?.toString(),
      adherence: json['adherence'] is Map
          ? LifestyleWeeklyAdherenceDto.fromJson(
              Map<String, dynamic>.from(json['adherence'] as Map),
            )
          : null,
      days: days,
    );
  }
}

/// Cycle adherence from the backend (`adherence`): done / skipped / pending / total / percent.
class LifestyleWeeklyAdherenceDto {
  final int done;
  final int skipped;
  final int pending;
  final int total;
  final int percent;

  const LifestyleWeeklyAdherenceDto({
    this.done = 0,
    this.skipped = 0,
    this.pending = 0,
    this.total = 0,
    this.percent = 0,
  });

  factory LifestyleWeeklyAdherenceDto.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => int.tryParse('$v') ?? 0;
    return LifestyleWeeklyAdherenceDto(
      done: asInt(json['done']),
      skipped: asInt(json['skipped']),
      pending: asInt(json['pending']),
      total: asInt(json['total']),
      percent: asInt(json['percent']),
    );
  }
}

class LifestyleWeeklyDayDto {
  final String localDate;
  final int dayIndex;
  final List<LifestyleWeeklyActionDto> nutrition;
  final List<LifestyleWeeklyActionDto> exercise;

  const LifestyleWeeklyDayDto({
    required this.localDate,
    required this.dayIndex,
    this.nutrition = const [],
    this.exercise = const [],
  });

  factory LifestyleWeeklyDayDto.fromJson(Map<String, dynamic> json) {
    List<LifestyleWeeklyActionDto> parseActions(dynamic raw) {
      final out = <LifestyleWeeklyActionDto>[];
      if (raw is! List) return out;
      for (final e in raw) {
        if (e is Map) {
          out.add(
            LifestyleWeeklyActionDto.fromJson(Map<String, dynamic>.from(e)),
          );
        }
      }
      return out;
    }

    return LifestyleWeeklyDayDto(
      localDate: json['local_date']?.toString() ?? '',
      dayIndex: int.tryParse('${json['day_index']}') ?? 0,
      nutrition: parseActions(json['nutrition']),
      exercise: parseActions(json['exercise']),
    );
  }
}

class LifestyleWeeklyActionDto {
  final int? id;
  final String? detail;
  final String? reviewOutcome;
  final String? reviewReason;
  final String? title;
  final String? status;
  final String? actionType;
  final String? localTime;
  final String? mealSlot;
  final String? activityType;
  final String? activityTitle;
  final int? durationMinutes;

  const LifestyleWeeklyActionDto({
    this.id,
    this.detail,
    this.reviewOutcome,
    this.reviewReason,
    this.title,
    this.status,
    this.actionType,
    this.localTime,
    this.mealSlot,
    this.activityType,
    this.activityTitle,
    this.durationMinutes,
  });

  factory LifestyleWeeklyActionDto.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    String? asStr(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      return s.isEmpty ? null : s;
    }

    final review = json['review'];
    return LifestyleWeeklyActionDto(
      id: asInt(json['id']),
      detail: asStr(json['detail']),
      reviewOutcome: review is Map ? asStr(review['outcome']) : null,
      reviewReason: review is Map ? asStr(review['reason']) : null,
      title: asStr(json['title']),
      status: asStr(json['status']),
      actionType: asStr(json['action_type']),
      localTime: asStr(json['local_time']),
      mealSlot: asStr(json['meal_slot']),
      activityType: asStr(json['activity_type']),
      activityTitle: asStr(json['activity_title']),
      durationMinutes: asInt(json['duration_minutes']),
    );
  }
}
