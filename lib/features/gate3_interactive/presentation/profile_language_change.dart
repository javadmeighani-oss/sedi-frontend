import '../../../core/locale/sedi_locale_controller.dart';
import '../../../core/network/api_response.dart';
import '../../../data/dto/auth/me_profile.dart';

enum ProfileLanguageOutcome { unchanged, changed, failed }

/// Profile language switch (account authority, same rule as A2): the app language changes only
/// after the backend has confirmed `preferred_language` through PATCH `/auth/me`.
class ProfileLanguageChange {
  ProfileLanguageChange._();

  static Future<ProfileLanguageOutcome> apply({
    required String current,
    required String selected,
    required Future<ApiResponse<MeProfileDto>> Function(MeUpdateDto update) patch,
    required SediLocaleController locale,
  }) async {
    final next = selected.trim().toLowerCase();
    if (next.isEmpty || next == current.trim().toLowerCase()) {
      return ProfileLanguageOutcome.unchanged;
    }
    final res = await patch(MeUpdateDto(preferredLanguage: next));
    final confirmed = res.data?.preferredLanguage?.trim().toLowerCase();
    if (!res.ok || confirmed != next) {
      return ProfileLanguageOutcome.failed;
    }
    await locale.reconcileFromBackendConfirmed(confirmed);
    return ProfileLanguageOutcome.changed;
  }
}
