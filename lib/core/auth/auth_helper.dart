import 'auth_service.dart';

/// راهنمای استفاده از سرویس احراز هویت
///
/// برای تنظیم توکن احراز هویت:
/// ```dart
/// await AuthService.setToken('your-token-here');
/// ```
///
/// برای دریافت توکن:
/// ```dart
/// final token = await AuthService.getToken();
/// ```
///
/// برای بررسی وجود توکن:
/// ```dart
/// final hasToken = await AuthService.hasToken();
/// ```
///
/// برای حذف توکن (خروج):
/// ```dart
/// await AuthService.clearToken();
/// ```

class AuthHelper {
  /// تنظیم توکن از یک endpoint لاگین (در صورت نیاز)
  /// این متد را می‌توانید برای لاگین استفاده کنید
  static Future<bool> login(String username, String password) async {
    // در حال حاضر باید توکن را به صورت دستی تنظیم کنید
    // await AuthService.setToken('your-token-from-backend');
    return false;
  }

  /// تنظیم توکن به صورت دستی (برای تست)
  static Future<bool> setTokenManually(String token) async {
    return await AuthService.setToken(token);
  }
}
