import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  static const String baseUrl = "http://91.107.168.130:8000";
  // اگر بعداً دامنه داشتی اینجا تغییر می‌دهیم

  Future<String> sendMessage(String userMessage) async {
    try {
      final url = Uri.parse("$baseUrl/chat");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": userMessage}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["reply"] ?? "خطا: پاسخ نامعتبر از سرور";
      } else {
        return "خطا در اتصال به سرور (${response.statusCode})";
      }
    } catch (e) {
      return "عدم اتصال به سرور";
    }
  }
}
