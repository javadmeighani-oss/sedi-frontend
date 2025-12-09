import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../core/auth/auth_service.dart';
import '../../core/config/app_config.dart';

class ChatService {

  /// ساخت هدرهای درخواست با Authorization
  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      "Content-Type": "application/json",
    };

    // افزودن هدر Authorization در صورت وجود توکن
    final token = await AuthService.getToken();
    if (token != null && token.isNotEmpty) {
      headers["Authorization"] = "Bearer $token";
    }

    return headers;
  }

  /// پاسخ‌های mock برای حالت لوکال
  String _getMockResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    final random = Random();

    // پاسخ‌های هوشمند بر اساس کلمات کلیدی
    if (message.contains('سلام') ||
        message.contains('hi') ||
        message.contains('hello')) {
      return 'سلام! خوش اومدی 😊\nچطور می‌تونم کمکت کنم؟';
    } else if (message.contains('چطوری') || message.contains('حالت')) {
      return 'من خوبم، ممنون که پرسیدی! تو چطوری؟ 😊';
    } else if (message.contains('اسم') || message.contains('کیستی')) {
      return 'من صدی هستم، دستیار هوشمند شما! 🤖✨';
    } else if (message.contains('کمک') || message.contains('help')) {
      return 'حتماً! می‌تونم در زمینه‌های مختلف کمکت کنم:\n• پاسخ به سوالات\n• راهنمایی\n• و خیلی چیزهای دیگه!\n\nبگو چی می‌خوای؟';
    } else if (message.contains('ساعت') || message.contains('زمان')) {
      final now = DateTime.now();
      return 'الان ساعت ${now.hour}:${now.minute.toString().padLeft(2, '0')} هست ⏰';
    } else if (message.contains('تاریخ') || message.contains('روز')) {
      final now = DateTime.now();
      return 'امروز ${now.year}/${now.month}/${now.day} هست 📅';
    } else if (message.contains('خداحافظ') || message.contains('bye')) {
      return 'خداحافظ! همیشه در خدمتت هستم 👋';
    } else if (message.contains('ممنون') || message.contains('تشکر')) {
      return 'خواهش می‌کنم! خوشحالم که تونستم کمکت کنم 😊';
    } else if (message.contains('چی') && message.contains('می‌کنی') ||
        message.contains('چه کار')) {
      return 'من اینجام تا بهت کمک کنم! می‌تونم:\n• به سوالاتت جواب بدم\n• راهنماییت کنم\n• و هر چیزی که نیاز داری!\n\nبگو چی می‌خوای؟';
    } else {
      // پاسخ‌های تصادفی برای پیام‌های دیگر
      final responses = [
        'جالب بود! می‌تونی بیشتر توضیح بدی؟ 🤔',
        'درسته! این موضوع رو بررسی می‌کنم... 💭',
        'خوب متوجه شدم! بذار ببینم چطور می‌تونم کمکت کنم... ✨',
        'ممنون از توضیحت! الان بررسی می‌کنم... 🔍',
        'عالی! این موضوع رو یادداشت کردم. چیز دیگه‌ای هم هست؟ 📝',
        'درست متوجه شدم! بذار ببینم چطور می‌تونم بهتر کمکت کنم... 💡',
      ];
      return responses[random.nextInt(responses.length)];
    }
  }

  Future<String> sendMessage(String userMessage) async {
    // حالت لوکال - بدون اتصال به بک‌اند
    if (AppConfig.useLocalMode) {
      // شبیه‌سازی تاخیر شبکه
      await Future.delayed(
          Duration(milliseconds: 500 + Random().nextInt(1000)));
      return _getMockResponse(userMessage);
    }

    // حالت واقعی - اتصال به بک‌اند
    try {
      final url = Uri.parse("${AppConfig.baseUrl}/chat");
      final headers = await _getHeaders();

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({"message": userMessage}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["reply"] ?? "خطا: پاسخ نامعتبر از سرور";
      } else if (response.statusCode == 401) {
        // خطای احراز هویت
        return "خطا: نیاز به احراز هویت مجدد";
      } else {
        // بررسی خطای JSON در پاسخ
        try {
          final errorData = jsonDecode(response.body);
          if (errorData.containsKey("Message")) {
            return "خطا: ${errorData["Message"]}";
          }
        } catch (_) {}
        return "خطا در اتصال به سرور (${response.statusCode})";
      }
    } catch (e) {
      return "عدم اتصال به سرور: ${e.toString()}";
    }
  }
}
