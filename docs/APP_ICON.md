# آیکن اپ (لانچر آیکن) – Sedi circular logo

آیکن لانچر باید: **دایره سفید + لوگوی سبز پسته‌ای صدی** در مرکز.

---

## ۱) منبع آیکن

- **فایل:** `assets/images/sedi_app_icon.png`
- **پیشنهاد:** مربع ۱۰۲۴×۱۰۲۴؛ محتوا: پس‌زمینه دایره سفید + لوگوی سبز پسته‌ای (صدی) در مرکز.
- اگر این فایل با طراحی بالا موجود نیست، آن را در ابزار طراحی بسازید و جایگزین کنید.

---

## ۲) تنظیم در pubspec.yaml

در `pubspec.yaml` باید وجود داشته باشد:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/sedi_app_icon.png"
```

وابستگی dev:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.4
```

---

## ۳) تولید آیکن‌های اندروید و iOS

از ریشهٔ پروژهٔ frontend:

```bash
flutter pub get
dart run flutter_launcher_icons
```

خروجی‌ها:
- **Android:** `android/app/src/main/res/mipmap-*` (ic_launcher.png در hdpi, mdpi, xhdpi, xxhdpi, xxxhdpi)
- **iOS:** `ios/Runner/Assets.xcassets/AppIcon.appiconset/` (آیکن‌های چند اندازه)

این فایل‌ها را کامیت کنید.

---

## ۴) نسخه / versionCode

برای اینکه دستگاهها بعد از نصب/به‌روزرسانی آیکن جدید را نشان دهند، عدد build را در `pubspec.yaml` افزایش دهید:

```yaml
version: 1.0.0+2   # عدد بعد از + (versionCode در اندروید) را زیاد کنید
```

---

## ۵) تأیید

- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
- **دستی:** نصب تازه (حذف نسخه قبلی در صورت نیاز) و بررسی آیکن روی دستگاه.
