# 📘 مستندات کامل پروژه صدی (Sedi)

## 🎯 معرفی پروژه

**صدی (Sedi)** یک دستیار هوشمند سلامت است که با استفاده از هوش مصنوعی، به کاربران کمک می‌کند تا اطلاعات سلامت خود را مدیریت کنند و راهنمایی‌های شخصی‌سازی شده دریافت کنند.

### ویژگی‌های کلیدی:
- 🤖 دستیار هوشمند با قابلیت مکالمه طبیعی
- 🌍 پشتیبانی از چند زبان (انگلیسی، فارسی، عربی)
- 💚 رابط کاربری زیبا با رنگ سازمانی سبز پسته‌ای
- 🔐 سیستم احراز هویت و مدیریت کاربر
- 📱 طراحی واکنش‌گرا برای موبایل
- 🔔 سیستم اعلان‌رسانی

---

## 🏗️ معماری پروژه

### ساختار کلی (Clean Architecture)

```
lib/
│
├── main.dart                    # نقطه ورود برنامه
├── app.dart                     # تنظیمات MaterialApp و Theme
│
├── core/                        # لایه هسته (Core Layer)
│   ├── config/                  # تنظیمات برنامه
│   │   └── app_config.dart      # URL بک‌اند و تنظیمات
│   ├── theme/                   # تم و استایل
│   │   └── app_theme.dart       # رنگ‌ها و تم اصلی
│   ├── network/                 # شبکه و API
│   │   └── api_client.dart      # کلاینت HTTP (خالی - آماده توسعه)
│   ├── auth/                    # احراز هویت
│   │   ├── auth_service.dart    # مدیریت توکن
│   │   └── auth_helper.dart     # Helper های احراز هویت
│   └── utils/                   # ابزارهای کمکی
│       ├── language_detector.dart  # تشخیص زبان
│       ├── messages.dart           # پیام‌های چندزبانه
│       └── user_preferences.dart   # تنظیمات کاربر
│
├── data/                        # لایه داده (Data Layer)
│   ├── models/                  # مدل‌های داده
│   │   ├── chat_message.dart    # مدل پیام چت
│   │   └── user_profile.dart    # پروفایل کاربر (خالی)
│   ├── dto/                     # Data Transfer Objects
│   │   ├── interact_request.dart   # درخواست تعامل (خالی)
│   │   └── interact_response.dart  # پاسخ تعامل (خالی)
│   └── repositories/            # مخازن داده
│       └── chat_repository.dart    # مخزن چت (خالی)
│
└── features/                    # لایه ویژگی‌ها (Feature Layer)
    ├── chat/                    # ویژگی چت
    │   ├── chat_service.dart    # سرویس چت (ارتباط با API)
    │   ├── presentation/        # لایه نمایش
    │   │   ├── pages/
    │   │   │   └── chat_page.dart      # صفحه اصلی چت
    │   │   └── widgets/
    │   │       ├── sedi_header.dart    # هدر با لوگو و حلقه تپنده
    │   │       ├── sedi_ring_anim.dart # انیمیشن حلقه
    │   │       ├── input_bar.dart      # نوار ورودی پیام
    │   │       ├── message_bubble.dart  # حباب پیام
    │   │       └── rotary_scrollbar.dart # اسکرول چرخشی
    │   └── state/
    │       ├── chat_controller.dart    # کنترلر وضعیت چت
    │       └── chat_message.dart       # مدل پیام در state
    │
    └── notification/            # ویژگی اعلان‌ها
        ├── data/
        │   └── models/
        │       └── sedi_notification.dart  # مدل اعلان
        ├── presentation/
        │   └── widgets/
        │       └── notification_card.dart # کارت اعلان
        └── logic/
            ├── notification_handler.dart   # مدیریت اعلان‌ها
            └── notification_test.dart      # تست اعلان‌ها
```

---

## 🔄 جریان ارتباط با بک‌اند

### 1. معماری ارتباط

```
┌─────────────────┐
│   ChatPage       │  (UI Layer)
│   (Widget)       │
└────────┬─────────┘
         │
         │ User Action
         ▼
┌─────────────────┐
│ ChatController  │  (State Management)
│ (ChangeNotifier)│
└────────┬─────────┘
         │
         │ sendMessage()
         ▼
┌─────────────────┐
│  ChatService    │  (Service Layer)
│  (API Client)   │
└────────┬─────────┘
         │
         │ HTTP POST
         ▼
┌─────────────────┐
│  Backend API    │  (http://91.107.168.130:8000)
│  /chat          │
└─────────────────┘
```

### 2. جریان کامل ارسال پیام

#### مرحله 1: کاربر پیام را تایپ می‌کند
```dart
// در InputBar widget
void _send() {
  final text = _controller.text.trim();
  widget.onSendText(text);  // به ChatPage ارسال می‌شود
}
```

#### مرحله 2: ChatPage به ChatController ارسال می‌کند
```dart
// در ChatPage
InputBar(
  onSendText: (text) {
    _controller.sendUserMessage(text);  // به Controller ارسال
  },
)
```

#### مرحله 3: ChatController پیام را پردازش می‌کند
```dart
// در ChatController
Future<void> sendUserMessage(String text) async {
  // 1. اضافه کردن پیام کاربر به لیست
  messages.add(ChatMessage(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    text: text,
    isUser: true,
    type: 'normal',
  ));
  
  // 2. نمایش حالت "در حال فکر کردن"
  isThinking = true;
  notifyListeners();
  
  // 3. ارسال به API
  try {
    final response = await _chatService.sendMessage(text);
    addSediMessage(response);
  } catch (e) {
    // مدیریت خطا
  }
}
```

#### مرحله 4: ChatService درخواست HTTP می‌فرستد
```dart
// در ChatService
Future<String> sendMessage(String userMessage) async {
  // حالت لوکال (Mock)
  if (AppConfig.useLocalMode) {
    await Future.delayed(Duration(milliseconds: 500));
    return _getMockResponse(userMessage);
  }
  
  // حالت واقعی (API)
  final url = Uri.parse("${AppConfig.baseUrl}/chat");
  final headers = await _getHeaders();  // شامل Authorization
  
  final response = await http.post(
    url,
    headers: headers,
    body: jsonEncode({"message": userMessage}),
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data["reply"] ?? "خطا: پاسخ نامعتبر";
  }
  
  // مدیریت خطاها
}
```

#### مرحله 5: پاسخ به UI برمی‌گردد
```dart
// در ChatController
void addSediMessage(String text) {
  isThinking = false;  // توقف انیمیشن
  
  messages.add(ChatMessage(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    text: text,
    isUser: false,  // پیام از صدی
    type: 'normal',
  ));
  
  notifyListeners();  // به‌روزرسانی UI
}
```

### 3. احراز هویت (Authentication)

#### نحوه کار:
```dart
// در ChatService._getHeaders()
Future<Map<String, String>> _getHeaders() async {
  final headers = <String, String>{
    "Content-Type": "application/json",
  };
  
  // دریافت توکن از SharedPreferences
  final token = await AuthService.getToken();
  if (token != null && token.isNotEmpty) {
    headers["Authorization"] = "Bearer $token";
  }
  
  return headers;
}
```

#### ذخیره توکن:
```dart
// بعد از لاگین موفق
await AuthService.setToken("your_jwt_token_here");
```

#### بررسی توکن:
```dart
// قبل از ارسال درخواست
final hasToken = await AuthService.hasToken();
if (!hasToken) {
  // هدایت به صفحه لاگین
}
```

### 4. فرمت درخواست و پاسخ API

#### درخواست (Request):
```json
POST /chat
Headers:
  Content-Type: application/json
  Authorization: Bearer <token>

Body:
{
  "message": "سلام صدی"
}
```

#### پاسخ موفق (Response - 200):
```json
{
  "reply": "سلام! چطور می‌تونم کمکت کنم؟"
}
```

#### پاسخ خطا (Response - 401):
```json
{
  "Message": "Unauthorized"
}
```

---

## 🎨 طراحی UI/UX

### رنگ‌های سازمانی:
- **سبز پسته‌ای (Pistachio Green)**: `#9BCF88` - رنگ اصلی
- **خاکستری متال (Metal Gray)**: `#B0B0B0` - رنگ ثانویه
- **سفید (White)**: `#FFFFFF` - پس‌زمینه
- **مشکی (Black)**: `#000000` - متن

### ساختار صفحه اصلی:
1. **لوگوی صدی** (بالا و وسط)
   - حلقه سبز پسته‌ای نازک
   - انیمیشن تپنده هنگام فکر کردن
   - اندازه: 140x140

2. **چت باکس** (زیر لوگو)
   - آیکن میکروفن (چپ)
   - فیلد ورودی (وسط)
   - آیکن ارسال (راست)
   - بزرگ شدن هنگام تایپ
   - کادر خاکستری متال

3. **آخرین پیام** (زیر چت باکس)
   - همیشه دیده می‌شود
   - حباب پیام با انیمیشن

4. **پیام‌های قدیمی** (با اسکرول)
   - اسکرول چرخشی سمت راست
   - فقط وقتی بیش از یک پیام وجود دارد

### انیمیشن‌ها:
- **حلقه تپنده**: هنگام `isThinking = true`
- **حباب پیام**: Fade + Slide هنگام اضافه شدن
- **چت باکس**: بزرگ شدن هنگام Focus

---

## 🌍 پشتیبانی چندزبانه

### زبان‌های پشتیبانی شده:
- **انگلیسی (en)**: زبان پیش‌فرض
- **فارسی (fa)**: RTL
- **عربی (ar)**: RTL

### نحوه تشخیص زبان:
```dart
// در LanguageDetector
static String detectLanguage(String text) {
  // تشخیص کاراکترهای فارسی/عربی
  final persianArabicRegex = RegExp(r'[\u0600-\u06FF...]');
  if (persianArabicRegex.hasMatch(text)) {
    // تشخیص فارسی یا عربی
    return 'fa' or 'ar';
  }
  return 'en';
}
```

### مدیریت زبان:
```dart
// در ChatController
String currentLanguage = 'en';

// تشخیص خودکار از پیام کاربر
final detectedLang = LanguageDetector.detectLanguage(text);
if (detectedLang != currentLanguage) {
  currentLanguage = detectedLang;
  await UserPreferences.saveUserLanguage(currentLanguage);
}
```

### پیام‌های چندزبانه:
```dart
// در AppMessages
static String getWelcomeMessage(String lang) {
  switch (lang) {
    case 'fa': return 'سلام! من صدی هستم...';
    case 'ar': return 'مرحبا! أنا سيدي...';
    default: return 'Hello! I\'m Sedi...';
  }
}
```

---

## 👤 مدیریت کاربر (Onboarding)

### جریان ورود اول:

```
1. بررسی isFirstTime
   ↓
2. نمایش خوشامد (انگلیسی)
   ↓
3. پرسیدن نام
   ↓
4. تشخیص زبان از نام
   ↓
5. پرسیدن رمز/کلمه عبور
   ↓
6. ذخیره اطلاعات
   ↓
7. تکمیل onboarding
```

### ذخیره اطلاعات:
```dart
// در UserPreferences
await saveUserName("احمد");
await saveUserPassword("کلمه_عبور_من");
await saveUserLanguage("fa");
await setNotFirstTime();
```

### بارگذاری اطلاعات:
```dart
// در ChatController.initialize()
if (!isFirstTime) {
  userName = await UserPreferences.getUserName();
  currentLanguage = await UserPreferences.getUserLanguage();
  // نمایش خوشامد مجدد
}
```

---

## 🔔 سیستم اعلان‌رسانی

### ساختار:
```
features/notification/
├── data/models/
│   └── sedi_notification.dart    # مدل اعلان
├── presentation/widgets/
│   └── notification_card.dart   # نمایش اعلان
└── logic/
    ├── notification_handler.dart # مدیریت اعلان‌ها
    └── notification_test.dart    # تست
```

### ویژگی‌های اعلان:
- نمایش کارت اعلان
- مدیریت وضعیت خوانده/نخوانده
- انیمیشن نمایش

---

## 🛠️ تنظیمات و پیکربندی

### AppConfig:
```dart
class AppConfig {
  // آدرس بک‌اند
  static const String baseUrl = "http://91.107.168.130:8000";
  
  // حالت لوکال (Mock) یا واقعی (API)
  static const bool useLocalMode = false;
}
```

### تغییر حالت:
- **توسعه/تست**: `useLocalMode = true` (استفاده از Mock)
- **تولید**: `useLocalMode = false` (اتصال به API واقعی)

---

## 📦 وابستگی‌ها (Dependencies)

### اصلی:
- `flutter`: SDK اصلی
- `http: ^1.2.0`: ارتباط HTTP با API
- `shared_preferences: ^2.2.2`: ذخیره داده‌های محلی
- `provider: ^6.1.1`: مدیریت state
- `intl: ^0.18.1`: بین‌المللی‌سازی

### توسعه:
- `flutter_test`: تست
- `flutter_lints: ^4.0.0`: لینتر

---

## 🚀 راهنمای توسعه مرحله دوم

### 1. تکمیل فایل‌های خالی

#### الف) `lib/core/network/api_client.dart`
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../auth/auth_service.dart';
import '../config/app_config.dart';

class ApiClient {
  // متدهای عمومی برای درخواست‌های HTTP
  // GET, POST, PUT, DELETE
  
  Future<Map<String, dynamic>> get(String endpoint) async {
    // پیاده‌سازی GET
  }
  
  Future<Map<String, dynamic>> post(
    String endpoint, 
    Map<String, dynamic> body
  ) async {
    // پیاده‌سازی POST
  }
}
```

#### ب) `lib/data/dto/interact_request.dart`
```dart
class InteractRequest {
  final String message;
  final String? userId;
  final String? sessionId;
  
  InteractRequest({
    required this.message,
    this.userId,
    this.sessionId,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'user_id': userId,
      'session_id': sessionId,
    };
  }
}
```

#### ج) `lib/data/dto/interact_response.dart`
```dart
class InteractResponse {
  final String reply;
  final String? sessionId;
  final Map<String, dynamic>? metadata;
  
  InteractResponse({
    required this.reply,
    this.sessionId,
    this.metadata,
  });
  
  factory InteractResponse.fromJson(Map<String, dynamic> json) {
    return InteractResponse(
      reply: json['reply'] ?? '',
      sessionId: json['session_id'],
      metadata: json['metadata'],
    );
  }
}
```

#### د) `lib/data/models/user_profile.dart`
```dart
class UserProfile {
  final String id;
  final String name;
  final String language;
  final DateTime? createdAt;
  
  UserProfile({
    required this.id,
    required this.name,
    required this.language,
    this.createdAt,
  });
  
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      language: json['language'] ?? 'en',
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : null,
    );
  }
}
```

#### ه) `lib/data/repositories/chat_repository.dart`
```dart
import '../../core/network/api_client.dart';
import '../dto/interact_request.dart';
import '../dto/interact_response.dart';

class ChatRepository {
  final ApiClient _apiClient = ApiClient();
  
  Future<InteractResponse> sendMessage(InteractRequest request) async {
    final response = await _apiClient.post(
      '/chat',
      request.toJson(),
    );
    return InteractResponse.fromJson(response);
  }
}
```

### 2. بهبود ChatService

#### استفاده از Repository:
```dart
class ChatService {
  final ChatRepository _repository = ChatRepository();
  
  Future<String> sendMessage(String userMessage) async {
    if (AppConfig.useLocalMode) {
      return _getMockResponse(userMessage);
    }
    
    final request = InteractRequest(
      message: userMessage,
      userId: await _getUserId(),
    );
    
    try {
      final response = await _repository.sendMessage(request);
      return response.reply;
    } catch (e) {
      return "خطا: ${e.toString()}";
    }
  }
}
```

### 3. افزودن ویژگی‌های جدید

#### الف) مدیریت Session:
```dart
// در ChatController
String? _sessionId;

Future<void> sendUserMessage(String text) async {
  // ...
  final request = InteractRequest(
    message: text,
    sessionId: _sessionId,
  );
  
  final response = await _chatService.sendMessage(text);
  _sessionId = response.sessionId;  // ذخیره session
}
```

#### ب) پشتیبانی از Voice Input:
```dart
// افزودن package: speech_to_text
// در InputBar
void _startVoiceInput() async {
  // شروع ضبط صدا
  // تبدیل به متن
  // ارسال به ChatController
}
```

#### ج) تاریخچه پیام‌ها:
```dart
// ذخیره پیام‌ها در دیتابیس محلی
// استفاده از package: sqflite یا hive
```

### 4. بهبود UI/UX

#### الف) صفحه پروفایل:
```dart
// features/profile/presentation/pages/profile_page.dart
class ProfilePage extends StatelessWidget {
  // نمایش اطلاعات کاربر
  // ویرایش نام
  // تغییر زبان
  // خروج از حساب
}
```

#### ب) صفحه تنظیمات:
```dart
// features/settings/presentation/pages/settings_page.dart
class SettingsPage extends StatelessWidget {
  // تنظیمات اعلان‌ها
  // تنظیمات زبان
  // تنظیمات تم
}
```

#### ج) بهبود انیمیشن‌ها:
```dart
// انیمیشن‌های بیشتر
// Transitions بین صفحات
// Loading states بهتر
```

### 5. تست و کیفیت

#### الف) Unit Tests:
```dart
// test/features/chat/chat_service_test.dart
void main() {
  test('sendMessage returns mock response in local mode', () {
    // تست
  });
}
```

#### ب) Widget Tests:
```dart
// test/features/chat/presentation/widgets/input_bar_test.dart
void main() {
  testWidgets('InputBar expands on focus', (tester) async {
    // تست
  });
}
```

#### ج) Integration Tests:
```dart
// integration_test/app_test.dart
void main() {
  testWidgets('Complete chat flow', (tester) async {
    // تست کامل جریان چت
  });
}
```

### 6. بهینه‌سازی

#### الف) Caching:
```dart
// کش کردن پاسخ‌های API
// استفاده از package: cached_network_image برای تصاویر
```

#### ب) Offline Support:
```dart
// ذخیره پیام‌ها برای استفاده آفلاین
// Queue برای ارسال پیام‌ها هنگام اتصال
```

#### ج) Performance:
```dart
// Lazy loading برای لیست پیام‌ها
// Image optimization
// Code splitting
```

---

## 📋 چک‌لیست توسعه مرحله دوم

### فاز 1: زیرساخت (Infrastructure)
- [ ] تکمیل `ApiClient`
- [ ] تکمیل DTOs (InteractRequest, InteractResponse)
- [ ] تکمیل Models (UserProfile)
- [ ] تکمیل Repository (ChatRepository)
- [ ] بهبود ChatService با استفاده از Repository

### فاز 2: ویژگی‌های اصلی (Core Features)
- [ ] مدیریت Session
- [ ] بهبود مدیریت خطا
- [ ] Retry mechanism برای درخواست‌های ناموفق
- [ ] Loading states بهتر
- [ ] Offline support

### فاز 3: UI/UX
- [ ] صفحه پروفایل
- [ ] صفحه تنظیمات
- [ ] بهبود انیمیشن‌ها
- [ ] Dark mode (اختیاری)
- [ ] بهبود Responsive design

### فاز 4: ویژگی‌های پیشرفته
- [ ] Voice Input
- [ ] Image Upload
- [ ] تاریخچه پیام‌ها (دیتابیس محلی)
- [ ] جستجو در تاریخچه
- [ ] Export تاریخچه

### فاز 5: تست و کیفیت
- [ ] Unit Tests
- [ ] Widget Tests
- [ ] Integration Tests
- [ ] Performance Testing
- [ ] Security Audit

### فاز 6: مستندسازی
- [ ] مستندات API
- [ ] مستندات کد
- [ ] راهنمای توسعه
- [ ] README به‌روز

---

## 🔐 امنیت

### بهترین روش‌ها:
1. **ذخیره امن توکن**: استفاده از `flutter_secure_storage` به جای `SharedPreferences`
2. **HTTPS**: استفاده از HTTPS برای تمام ارتباطات
3. **Certificate Pinning**: برای امنیت بیشتر
4. **Input Validation**: اعتبارسنجی ورودی‌های کاربر
5. **Error Handling**: عدم نمایش اطلاعات حساس در خطاها

---

## 📱 Build و Deploy

### Android:
```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

### iOS:
```bash
# Build IPA
flutter build ipa --release
```

### GitHub Actions:
- Workflow موجود در `.github/workflows/build-android.yml`
- Build خودکار با هر push به `main`
- APK آماده دانلود از Actions

---

## 🐛 مدیریت خطا

### انواع خطاها:
1. **Network Error**: عدم اتصال به اینترنت
2. **API Error**: خطای سرور (4xx, 5xx)
3. **Auth Error**: خطای احراز هویت (401)
4. **Parse Error**: خطای پارس JSON

### مدیریت خطا:
```dart
try {
  final response = await _chatService.sendMessage(text);
  addSediMessage(response);
} on NetworkException catch (e) {
  addSediMessage("خطا در اتصال به اینترنت");
} on ApiException catch (e) {
  addSediMessage("خطا از سمت سرور: ${e.message}");
} catch (e) {
  addSediMessage("خطای ناشناخته: ${e.toString()}");
}
```

---

## 📞 ارتباط با تیم

### نکات مهم:
1. **Commit Messages**: استفاده از فرمت استاندارد
   - `feat: اضافه کردن ویژگی جدید`
   - `fix: رفع باگ`
   - `refactor: بازنویسی کد`
   - `docs: به‌روزرسانی مستندات`

2. **Code Review**: بررسی کد قبل از merge
3. **Testing**: تست قبل از commit
4. **Documentation**: مستندسازی کدهای جدید

---

## 🎯 نقشه راه آینده

### کوتاه‌مدت (1-2 ماه):
- تکمیل زیرساخت
- بهبود UI/UX
- افزودن Voice Input
- تست‌های اولیه

### میان‌مدت (3-6 ماه):
- ویژگی‌های پیشرفته
- بهینه‌سازی عملکرد
- پشتیبانی از پلتفرم‌های بیشتر
- بهبود امنیت

### بلندمدت (6+ ماه):
- ویژگی‌های AI پیشرفته
- یکپارچه‌سازی با سرویس‌های سلامت
- Analytics و Reporting
- Community Features

---

## 📚 منابع و مراجع

### مستندات Flutter:
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)

### معماری:
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples)

### Best Practices:
- [Flutter Best Practices](https://flutter.dev/docs/development/ui/widgets-intro)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)

---

**آخرین به‌روزرسانی**: 2024
**نسخه**: 1.0.0
**نگهدارنده**: تیم توسعه صدی

