import 'package:flutter/material.dart';

import '../../../../core/theme/sedi_glass.dart';
import '../../../auth_otp/presentation/birth_calendar_helper.dart';
import '../gate3_localization.dart';

/// The result of editing the date of birth: the calendar the user picked in plus the ISO (Gregorian) date.
class ProfileBirthEdit {
  final String calendarType;
  final int year;
  final int month;
  final int day;
  final String isoDate;

  const ProfileBirthEdit({
    required this.calendarType,
    required this.year,
    required this.month,
    required this.day,
    required this.isoDate,
  });
}

/// Javad 2026-11-09: name, date of birth and sex are editable in the profile, like the language and the phone.
/// Each editor only asks; the page sends the result with PATCH /auth/me.
class ProfileIdentityEditor {
  ProfileIdentityEditor._();

  /// A small dialog with one text field. Returns the trimmed new name, or null when cancelled / empty.
  static Future<String?> editName(
    BuildContext context, {
    required Gate3Localization l10n,
    required String? current,
  }) async {
    final controller = TextEditingController(text: current ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profileEditNameTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(hintText: l10n.profileNameLabel),
          onSubmitted: (value) {
            final v = value.trim();
            if (v.isNotEmpty) Navigator.of(ctx).pop(v);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.profileEditCancel),
          ),
          TextButton(
            onPressed: () {
              final v = controller.text.trim();
              if (v.isNotEmpty) Navigator.of(ctx).pop(v);
            },
            child: Text(l10n.profileEditSave),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  /// A bottom sheet with the three backend sex codes. Returns `male`, `female` or `other`, or null when dismissed.
  static Future<String?> editSex(
    BuildContext context, {
    required Gate3Localization l10n,
    required String? current,
  }) {
    const codes = <String>['male', 'female', 'other'];
    final selected = (current ?? '').trim().toLowerCase();
    return showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                l10n.profileEditSexTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: SediGlass.ink,
                ),
              ),
            ),
            for (final code in codes)
              ListTile(
                title: Text(l10n.profileSexValue(code)),
                trailing: selected == code
                    ? const Icon(Icons.check_rounded, color: SediGlass.ink)
                    : null,
                onTap: () => Navigator.of(ctx).pop(code),
              ),
          ],
        ),
      ),
    );
  }

  /// A dialog with day / month / year drop-downs in the user's calendar (Jalali, Hijri or Gregorian), like at sign-up.
  static Future<ProfileBirthEdit?> editBirth(
    BuildContext context, {
    required Gate3Localization l10n,
    required String language,
    String? calendarType,
    int? year,
    int? month,
    int? day,
  }) {
    final calendar = (calendarType != null && calendarType.isNotEmpty)
        ? calendarType
        : BirthCalendarHelper.calendarTypeForLanguage(language);
    final years = BirthCalendarHelper.yearRange(calendar);
    final fallback = BirthCalendarHelper.defaultSelection(calendar); // [day, month, year]
    var selectedYear = (year != null && years.contains(year)) ? year : fallback[2];
    var selectedMonth = (month != null && month >= 1 && month <= 12) ? month : fallback[1];
    var selectedDay = (day != null && day >= 1 && day <= 31) ? day : fallback[0];
    return showDialog<ProfileBirthEdit>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final maxDay = BirthCalendarHelper.daysInMonth(
            calendarType: calendar,
            year: selectedYear,
            month: selectedMonth,
          );
          if (selectedDay > maxDay) selectedDay = maxDay;
          Widget drop(String label, int value, List<int> items, ValueChanged<int> onChanged) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: DropdownButtonFormField<int>(
                  value: value,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: label),
                  items: [
                    for (final v in items)
                      DropdownMenuItem<int>(value: v, child: Text('$v')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => onChanged(v));
                  },
                ),
              ),
            );
          }

          return AlertDialog(
            title: Text(l10n.profileEditBirthTitle),
            content: Row(
              children: [
                drop(l10n.profileDayLabel, selectedDay,
                    List<int>.generate(maxDay, (i) => i + 1), (v) => selectedDay = v),
                drop(l10n.profileMonthLabel, selectedMonth,
                    List<int>.generate(12, (i) => i + 1), (v) => selectedMonth = v),
                drop(l10n.profileYearLabel, selectedYear, years, (v) => selectedYear = v),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.profileEditCancel),
              ),
              TextButton(
                onPressed: () {
                  final iso = BirthCalendarHelper.toIsoDate(
                    calendarType: calendar,
                    day: selectedDay,
                    month: selectedMonth,
                    year: selectedYear,
                  );
                  if (iso == null) return;
                  Navigator.of(ctx).pop(ProfileBirthEdit(
                    calendarType: calendar,
                    year: selectedYear,
                    month: selectedMonth,
                    day: selectedDay,
                    isoDate: iso,
                  ));
                },
                child: Text(l10n.profileEditSave),
              ),
            ],
          );
        },
      ),
    );
  }
}
