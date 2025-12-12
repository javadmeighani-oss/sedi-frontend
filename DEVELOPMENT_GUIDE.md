# 🚀 راهنمای سریع توسعه صدی

## 📋 دستورات ضروری

### Setup اولیه:
```bash
# نصب وابستگی‌ها
flutter pub get

# بررسی مشکلات
flutter analyze

# اجرای برنامه
flutter run
```

### Build:
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS (نیاز به Mac)
flutter build ios --release
```

### Git:
```bash
# بررسی وضعیت
git status

# اضافه کردن تغییرات
git add -A

# Commit
git commit -m "feat: توضیح تغییرات"

# Push
git push origin main
```

---

## 🔧 تنظیمات مهم

### تغییر آدرس بک‌اند:
```dart
// lib/core/config/app_config.dart
static const String baseUrl = "http://YOUR_BACKEND_URL:PORT";
```

### تغییر حالت (Local/Production):
```dart
// lib/core/config/app_config.dart
static const bool useLocalMode = false;  // true = Mock, false = Real API
```

---

## 🏗️ ساختار فایل‌های جدید

### ایجاد Feature جدید:
```
lib/features/YOUR_FEATURE/
├── presentation/
│   ├── pages/
│   │   └── your_page.dart
│   └── widgets/
│       └── your_widget.dart
├── state/
│   └── your_controller.dart
└── your_service.dart
```

### ایجاد Model جدید:
```dart
// lib/data/models/your_model.dart
class YourModel {
  final String id;
  final String name;
  
  YourModel({required this.id, required this.name});
  
  factory YourModel.fromJson(Map<String, dynamic> json) {
    return YourModel(
      id: json['id'],
      name: json['name'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
```

---

## 🔄 الگوهای کدنویسی

### State Management (Provider):
```dart
// Controller
class YourController extends ChangeNotifier {
  String _data = '';
  
  String get data => _data;
  
  void updateData(String newData) {
    _data = newData;
    notifyListeners();
  }
}

// استفاده در Widget
class YourWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<YourController>(
      builder: (context, controller, child) {
        return Text(controller.data);
      },
    );
  }
}
```

### API Call:
```dart
Future<String> fetchData() async {
  try {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/endpoint'),
      headers: await _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['result'];
    } else {
      throw Exception('Failed to load data');
    }
  } catch (e) {
    throw Exception('Error: $e');
  }
}
```

### Local Storage:
```dart
// ذخیره
final prefs = await SharedPreferences.getInstance();
await prefs.setString('key', 'value');

// خواندن
final value = prefs.getString('key');
```

---

## 🎨 الگوهای UI

### Button با رنگ سازمانی:
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppTheme.pistachioGreen,
    foregroundColor: Colors.white,
  ),
  onPressed: () {},
  child: Text('Button'),
)
```

### Input Field:
```dart
TextField(
  decoration: InputDecoration(
    hintText: 'Placeholder',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
    ),
  ),
)
```

### Card:
```dart
Card(
  elevation: 2,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Text('Content'),
  ),
)
```

---

## 🐛 Debugging

### Print Debug:
```dart
print('Debug: $variable');
debugPrint('Debug: $variable');  // بهتر برای Flutter
```

### Breakpoints:
- در VS Code/Android Studio
- کلیک روی شماره خط برای breakpoint
- F5 برای شروع debug

### Flutter Inspector:
```bash
flutter run
# سپس در DevTools: Flutter Inspector
```

---

## ✅ Checklist قبل از Commit

- [ ] کد بدون خطا (`flutter analyze`)
- [ ] تست‌ها پاس می‌شوند
- [ ] UI درست کار می‌کند
- [ ] API calls درست هستند
- [ ] Error handling وجود دارد
- [ ] Comments اضافه شده
- [ ] Commit message واضح است

---

## 📝 Commit Message Format

```
feat: اضافه کردن ویژگی جدید
fix: رفع باگ
refactor: بازنویسی کد
docs: به‌روزرسانی مستندات
style: تغییرات فرمت
test: اضافه کردن تست
chore: کارهای نگهداری
```

---

## 🔍 Troubleshooting

### مشکل: `flutter pub get` خطا می‌دهد
```bash
flutter clean
flutter pub get
```

### مشکل: Build خطا می‌دهد
```bash
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
flutter build apk --release
```

### مشکل: Hot Reload کار نمی‌کند
```bash
# Restart کامل
r در terminal
# یا
flutter run
```

---

## 📦 افزودن Package جدید

1. اضافه کردن به `pubspec.yaml`:
```yaml
dependencies:
  new_package: ^1.0.0
```

2. نصب:
```bash
flutter pub get
```

3. Import:
```dart
import 'package:new_package/new_package.dart';
```

---

## 🌐 API Endpoints

### فعلی:
- `POST /chat` - ارسال پیام

### پیشنهادی برای آینده:
- `GET /user/profile` - دریافت پروفایل
- `PUT /user/profile` - به‌روزرسانی پروفایل
- `GET /chat/history` - تاریخچه پیام‌ها
- `POST /auth/login` - ورود
- `POST /auth/logout` - خروج

---

## 🎯 نکات مهم

1. **همیشه از AppConfig استفاده کنید** برای URL ها
2. **همیشه Error Handling داشته باشید**
3. **از Provider برای State Management استفاده کنید**
4. **کد را Clean و Readable نگه دارید**
5. **Comments اضافه کنید** برای کدهای پیچیده
6. **از Constants استفاده کنید** برای مقادیر ثابت
7. **Responsive Design** را در نظر بگیرید

---

**آخرین به‌روزرسانی**: 2024

