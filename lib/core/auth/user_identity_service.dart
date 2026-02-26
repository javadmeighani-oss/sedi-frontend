import '../network/api_client.dart';
import 'auth_service.dart';
import '../utils/user_profile_manager.dart';

class UserIdentityService {
  UserIdentityService._();

  static int? _cachedUserId;
  static Future<int?>? _inflightResolve;

  static Future<int?> resolveUserId({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      if (_cachedUserId != null && _cachedUserId! > 0) return _cachedUserId;
      final profile = await UserProfileManager.loadProfile();
      if (profile.userId != null && profile.userId! > 0) {
        _cachedUserId = profile.userId;
        return _cachedUserId;
      }
    }

    if (_inflightResolve != null) return _inflightResolve;
    _inflightResolve = _resolveViaAuthMe();
    final result = await _inflightResolve;
    _inflightResolve = null;
    return result;
  }

  static Future<int?> _resolveViaAuthMe() async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return null;

    final api = ApiClient();
    final me = await api.get<Map<String, dynamic>>(
      '/auth/me',
      extraHeaders: {'Authorization': 'Bearer $token'},
      parser: (json) => json is Map ? Map<String, dynamic>.from(json) : null,
    );
    if (!me.ok || me.data == null) return null;

    final rawUserId = me.data!['user_id'];
    final userId = rawUserId is int
        ? rawUserId
        : int.tryParse(rawUserId?.toString() ?? '');
    if (userId == null || userId <= 0) return null;

    final profile = await UserProfileManager.loadProfile();
    await UserProfileManager.saveProfile(
      profile.copyWith(
        userId: userId,
        phoneNumber: me.data!['phone']?.toString() ?? profile.phoneNumber,
        preferredLanguage:
            me.data!['language']?.toString() ?? profile.preferredLanguage,
        isVerified: true,
      ),
    );
    _cachedUserId = userId;
    return userId;
  }
}
