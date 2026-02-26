import 'lifestyle_entry_dto.dart';

class LifestyleUpdateRequestDto {
  final int userId;
  final List<LifestyleEntryDto> entries;

  const LifestyleUpdateRequestDto({
    required this.userId,
    required this.entries,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'entries': entries.map((e) => e.toJson()).toList(growable: false),
    };
  }
}
