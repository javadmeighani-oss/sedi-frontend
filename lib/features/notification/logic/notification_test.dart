import '../../../data/models/chat_message.dart';

class NotificationTest {
  /// تست نوتیف صبح بخیر
  static ChatMessage goodMorning() {
    return ChatMessage(
      id: "test_1",
      text:
          "صبح بخیر جواد 🌱\nامروز خوابت کمی کمتر بوده. می‌خوای یک تمرین تنفسی سریع انجام بدیم؟",
      isSedi: true,
      isUser: false,
      type: "notification",
      title: "Good Morning",
      quickReplies: ["باشه", "بیشتر بگو", "بعداً"],
    );
  }

  /// تست نوتیف احساسی
  static ChatMessage emotionalCheck() {
    return ChatMessage(
      id: "test_2",
      text: "مدتی هست ازت خبری نیست… حالت خوبه؟ 🌿",
      isSedi: true,
      isUser: false,
      type: "notification",
      title: "Feeling Check",
      quickReplies: ["آره", "نه خیلی", "بعداً"],
    );
  }

  /// تست هشدار سلامت
  static ChatMessage healthAlert() {
    return ChatMessage(
      id: "test_3",
      text: "❗ وضعیت ضربان قلبت غیرعادیه. لطفاً چند لحظه بشین و عمیق نفس بکش.",
      isSedi: true,
      isUser: false,
      type: "notification",
      title: "Health Alert",
      quickReplies: ["باشه", "چرا؟", "کمکم کن"],
    );
  }
}
