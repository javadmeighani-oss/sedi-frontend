# Sedi Frontend

فرانت‌اند اپلیکیشن صدی - دستیار هوشمند

## 🚀 اجرای لوکال

این برنامه به صورت پیش‌فرض در حالت **لوکال** اجرا می‌شود و نیازی به اتصال به بک‌اند ندارد.

### تنظیمات

در فایل `lib/core/config/app_config.dart`:

```dart
static const bool useLocalMode = false;  // حالت واقعی (اتصال به بک‌اند)
```

- `true`: اجرای لوکال با پاسخ‌های mock (بدون نیاز به بک‌اند)
- `false`: اتصال به بک‌اند واقعی

### اجرای برنامه

#### روش 1: استفاده از اسکریپت (پیشنهادی)
```bash
# برای Windows PowerShell
.\run.ps1

# یا برای Command Prompt
run.bat
```

#### روش 2: اجرای دستی
```bash
# نصب وابستگی‌ها
flutter pub get

# اجرا روی امولاتور/دستگاه
flutter run -t lib/main.dart
```

## ✨ ویژگی‌ها

- ✅ طراحی مدرن و زیبا
- ✅ انیمیشن‌های روان
- ✅ حالت لوکال برای تست بدون بک‌اند
- ✅ پشتیبانی از پیام‌های کاربر و صدی
- ✅ اسکرول‌بار چرخنده
- ✅ انیمیشن حلقه دور لوگو
- ✅ ورودی صوتی (آماده برای پیاده‌سازی)

## 📱 ساختار پروژه

```
lib/
├── core/
│   ├── auth/          # مدیریت احراز هویت
│   ├── config/        # تنظیمات برنامه
│   ├── network/       # کلاینت شبکه
│   └── theme/         # تم و استایل
├── features/
│   └── chat/          # ویژگی چت
│       ├── chat_service.dart
│       ├── state/
│       └── presentation/
└── main.dart
```

## 🎨 طراحی

- رنگ اصلی: سبز پسته‌ای (#7CB342)
- Material Design 3
- انیمیشن‌های نرم و روان
- UI/UX بهینه برای موبایل

## 📝 یادداشت

برای تغییر به حالت واقعی (اتصال به بک‌اند)، `useLocalMode` را در `app_config.dart` به `false` تغییر دهید.

## 🔧 Build برای Android

```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

## 🚀 GitHub Actions و تست روی موبایل اندروید

با پوش کردن کد به گیت‌هاب، workflow به‌صورت خودکار APK می‌سازد. برای **دانلود APK و نصب روی گوشی اندروید** راهنمای گام‌به‌گام را ببینید:

- **[راهنمای ساخت APK با GitHub Actions و تست روی موبایل](docs/BUILD_ANDROID_GITHUB_ACTIONS.md)**

خلاصه: پوش به `main`/`develop` → تب **Actions** در گیت‌هاب → دانلود Artifact با نام **sedi-android-apk** → نصب APK روی گوشی.
