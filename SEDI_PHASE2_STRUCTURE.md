# 📱 ساختار فرانت صدی - فاز 2

## 🎯 نمای کلی پروژه

**نام پروژه:** Sedi Intelligent Health Assistant  
**فریمورک:** Flutter (Dart)  
**معماری:** Feature-Based Clean Architecture  
**State Management:** Provider (ChangeNotifier)  
**Build System:** GitHub Actions CI/CD  

---

## 📂 ساختار دایرکتوری

```
frontend/
├── lib/
│   ├── main.dart                    # Entry point
│   ├── app.dart                     # MaterialApp configuration
│   │
│   ├── core/                        # Core utilities & infrastructure
│   │   ├── theme/
│   │   │   └── app_theme.dart       # Visual identity (colors, radius, shadows)
│   │   ├── utils/
│   │   │   ├── language_detector.dart
│   │   │   ├── user_preferences.dart
│   │   │   └── messages.dart
│   │   ├── auth/
│   │   │   ├── auth_service.dart
│   │   │   └── auth_helper.dart
│   │   ├── network/
│   │   │   └── api_client.dart
│   │   └── config/
│   │       └── app_config.dart
│   │
│   ├── data/                        # Data layer
│   │   ├── models/
│   │   │   ├── chat_message.dart
│   │   │   └── user_profile.dart
│   │   ├── dto/
│   │   │   ├── interact_request.dart
│   │   │   └── interact_response.dart
│   │   └── repositories/
│   │       └── chat_repository.dart
│   │
│   ├── features/                    # Feature modules
│   │   ├── chat/
│   │   │   ├── chat_service.dart
│   │   │   ├── state/
│   │   │   │   └── chat_controller.dart
│   │   │   └── presentation/
│   │   │       ├── pages/
│   │   │       │   ├── chat_page.dart
│   │   │       │   └── chat_history_page.dart
│   │   │       └── widgets/
│   │   │           ├── input_bar.dart
│   │   │           ├── message_bubble.dart
│   │   │           ├── sedi_header.dart
│   │   │           └── sedi_ring_anim.dart
│   │   │
│   │   └── notification/
│   │       ├── data/models/
│   │       │   └── sedi_notification.dart
│   │       ├── logic/
│   │       │   ├── notification_handler.dart
│   │       │   └── notification_test.dart
│   │       └── presentation/widgets/
│   │           └── notification_card.dart
│   │
│   └── utils/
│       └── time_utils.dart
│
├── assets/
│   └── images/
│       ├── sedi_logo_1024.png
│       └── logo/
│
├── android/                         # Android native (DO NOT MODIFY)
├── ios/                             # iOS native (DO NOT MODIFY)
├── pubspec.yaml                     # Dependencies
└── README.md
```

---

## 🎨 هویت بصری (AppTheme)

### رنگ‌های اصلی

| رنگ | کد | کاربرد |
|-----|-----|--------|
| **Pistachio Green** | `#8BC34A` | حلقه لوگو، دکمه‌های فعال |
| **Metal Grey** | `#9E9E9E` | آیکن‌های غیرفعال، border |
| **Primary Black** | `#111111` | متن، آیکن‌های فعال |
| **Background White** | `#FFFFFF` | پس‌زمینه اصلی |

### Radius Values

- `radiusSmall`: 8px
- `radiusMedium`: 14px
- `radiusLarge`: 18px

### Shadows

- `softShadow`: سایه نرم و مینیمال

**⚠️ قانون:** `app_theme.dart` فقط رنگ، radius و shadow دارد. بدون UI widget و بدون logic.

---

## 🏗️ معماری و مسئولیت‌ها

### 1. Core Layer

#### `app_theme.dart`
- **مسئولیت:** تنها منبع رنگ‌ها و استایل‌های بصری
- **محتوا:** رنگ‌ها، radius، shadow
- **ممنوع:** UI widgets، logic، imports غیرضروری

#### `language_detector.dart`
- **مسئولیت:** تشخیص زبان کاربر (انگلیسی، فارسی، عربی)
- **الگوریتم:** Regex-based detection

#### `user_preferences.dart`
- **مسئولیت:** ذخیره و بازیابی داده‌های کاربر
- **داده‌ها:** نام، رمز عبور، زبان، وضعیت onboarding

#### `api_client.dart`
- **مسئولیت:** ارتباط با Backend API
- **متدها:** GET, POST, error handling

---

### 2. Data Layer

#### `chat_message.dart`
```dart
class ChatMessage {
  final String id;
  final String text;
  final bool isSedi;
  final String type;              // "normal" | "notification"
  final String? title;            // برای notification
  final List<String>? quickReplies; // پاسخ‌های سریع
}
```

#### `chat_repository.dart`
- **مسئولیت:** مدیریت داده‌های چت
- **عملیات:** ذخیره، بازیابی، فیلتر

---

### 3. Features Layer

## 💬 Chat Feature

### `chat_controller.dart` (State Management)
- **مسئولیت:** مدیریت state چت
- **State:**
  - `isThinking`: آیا صدی در حال فکر است؟
  - `isAlert`: آیا هشدار فعال است؟
  - `isRecording`: آیا در حال ضبط صدا است؟
  - `recordingDuration`: مدت زمان ضبط
  - `messages`: لیست پیام‌ها
  - `currentLanguage`: زبان فعلی
  - `onboardingState`: وضعیت onboarding

- **متدها:**
  - `initialize()`: راه‌اندازی اولیه
  - `sendUserMessage(String)`: ارسال پیام متنی
  - `startVoiceRecording()`: شروع ضبط صدا
  - `stopVoiceRecording()`: توقف ضبط و ارسال
  - `recordingTimeFormatted`: زمان فرمت شده

**⚠️ قانون:** فقط state management. بدون UI، بدون animation، بدون widget imports.

### `chat_page.dart` (Layout Orchestration)
- **مسئولیت:** چیدمان کلی صفحه چت
- **اجزا:**
  - Top Bar (آیکن‌های favorite و history)
  - SediHeader (لوگو و حلقه)
  - Messages Area (ListView با scroll)
  - Last Message (همیشه دیده می‌شود)
  - InputBar

**⚠️ قانون:** فقط layout. بدون business logic، بدون gesture logic.

### `input_bar.dart` (Input UI & Gestures)
- **مسئولیت:** تمام UI و gestureهای ورودی
- **ویژگی‌ها:**
  - TextField برای تایپ
  - آیکن ارسال (سمت راست)
  - آیکن اسپیکر (چپ آیکن ارسال)
  - Expansion هنگام باز شدن کیبورد
  - نمایش تایمر ضبط صدا
  - بازخورد بصری (رنگ‌ها)

- **رفتار آیکن ارسال:**
  - بدون متن: `metalGrey` (غیرفعال)
  - با متن: `primaryBlack` (فعال)
  - هنگام لمس: تغییر رنگ به `primaryBlack` (بازخورد)

- **رفتار آیکن اسپیکر:**
  - لمس اول: شروع ضبط، رنگ → `primaryBlack`
  - در حال ضبط: نمایش تایمر، رنگ `primaryBlack`
  - لمس دوم: توقف ضبط و ارسال، رنگ → `metalGrey`

**⚠️ قانون:** فقط `metalGrey` و `primaryBlack`. بدون green، بدون opacity hacks.

### `sedi_header.dart`
- **مسئولیت:** نمایش لوگو و حلقه
- **ویژگی‌ها:**
  - لوگو: ثابت (static)
  - حلقه: انیمیشن heartbeat هنگام `isThinking` یا `isAlert`
  - اندازه: 168px (20% بزرگ‌تر از قبل)

### `sedi_ring_anim.dart`
- **مسئولیت:** انیمیشن حلقه (heartbeat)
- **ویژگی‌ها:**
  - Custom `_HeartbeatCurve` برای تپش طبیعی
  - Duration: 1100ms
  - Scale: 1.0 → 1.08
  - Opacity: دینامیک (0.30 → 0.95)
  - BoxShadow: glow effect

### `message_bubble.dart`
- **مسئولیت:** نمایش پیام‌های چت
- **ویژگی‌ها:**
  - تشخیص RTL برای فارسی/عربی
  - استایل متفاوت برای پیام کاربر و صدی
  - Border radius متفاوت

### `chat_history_page.dart`
- **مسئولیت:** نمایش تاریخچه چت
- **دسته‌بندی:**
  - Today
  - Yesterday
  - This Week
  - This Month
  - This Year
  - Older (grouped by year)

### `chat_service.dart`
- **مسئولیت:** ارتباط با Backend برای ارسال/دریافت پیام
- **متدها:**
  - `sendMessage(String)`: ارسال پیام و دریافت پاسخ

---

## 🔔 Notification Feature

### `notification_handler.dart`
- **مسئولیت:** پردازش notificationهای دریافتی
- **عملیات:** تبدیل JSON به `ChatMessage` با type "notification"

### `notification_test.dart`
- **مسئولیت:** Mock data برای تست notificationها

### `notification_card.dart`
- **مسئولیت:** نمایش notification با quick replies

---

## 🔄 Flow های اصلی

### 1. Onboarding Flow

```
اولین بار:
1. ChatController.initialize() → isFirstTime = true
2. نمایش پیام خوش‌آمد (انگلیسی)
3. درخواست نام کاربر
4. ذخیره نام → درخواست رمز عبور
5. ذخیره رمز → onboardingState = completed
6. تشخیص زبان از پیام کاربر
7. تطبیق زبان و ادامه مکالمه
```

### 2. Text Message Flow

```
1. کاربر متن را تایپ می‌کند → InputBar
2. فشردن آیکن ارسال → InputBar._sendText()
3. فراخوانی ChatController.sendUserMessage()
4. اضافه شدن پیام به messages
5. isThinking = true → حلقه شروع به تپش
6. ChatService.sendMessage() → API call
7. دریافت پاسخ → _addSediMessage()
8. isThinking = false → حلقه متوقف
```

### 3. Voice Recording Flow

```
1. لمس آیکن اسپیکر → InputBar._handleMicTap()
2. ChatController.startVoiceRecording()
   - isRecording = true
   - recordingDuration = 0
   - شروع تایمر
3. نمایش تایمر در InputBar
4. لمس مجدد آیکن → ChatController.stopVoiceRecording()
   - isRecording = false
   - اضافه شدن "[Voice Message]" به messages
   - isThinking = true
5. دریافت پاسخ متنی از صدی
```

---

## 🎯 Contract Freeze (قوانین ثابت)

### File Responsibility

1. **هر فایل یک مسئولیت دارد**
2. **بدون duplicate logic**
3. **بدون mix UI و state**
4. **بدون imports غیرضروری**

### AppTheme

- ✅ فقط رنگ، radius، shadow
- ❌ بدون UI widget
- ❌ بدون logic

### ChatController

- ✅ فقط state management
- ❌ بدون UI
- ❌ بدون animation
- ❌ بدون widget imports

### InputBar

- ✅ تمام UI و gestureهای ورودی
- ✅ فقط `metalGrey` و `primaryBlack`
- ❌ بدون green
- ❌ بدون opacity hacks

### ChatPage

- ✅ فقط layout orchestration
- ❌ بدون business logic
- ❌ بدون gesture logic

---

## 📦 Dependencies

```yaml
dependencies:
  flutter: SDK
  cupertino_icons: ^1.0.6
  http: ^1.2.0              # API calls
  shared_preferences: ^2.2.2 # Local storage
  provider: ^6.1.1          # State management
  intl: ^0.18.1              # Date formatting
```

---

## 🚀 Build & Deployment

### GitHub Actions CI/CD

- **Build:** خودکار با هر push به `main`
- **Platform:** Android APK
- **Download:** از بخش Artifacts در GitHub Actions

### دستورات Git

```powershell
# بررسی وضعیت
git status

# اضافه کردن تغییرات
git add .

# Commit
git commit -m "fix(frontend): description"

# Push
git push origin main
```

**⚠️ مهم:** Build فقط در GitHub Actions انجام می‌شود. خطاهای local `pub.dev` نادیده گرفته می‌شوند.

---

## 🌍 پشتیبانی از زبان‌ها

### زبان‌های پشتیبانی شده

1. **English** (پیش‌فرض)
2. **Farsi (فارسی)**
3. **Arabic (عربی)**

### تشخیص خودکار زبان

- الگوریتم: Regex-based detection
- زمان: بعد از onboarding
- ذخیره: در SharedPreferences

---

## 🎨 UI/UX Principles

### Design Philosophy

1. **مینیمالیسم:** طراحی ساده و تمیز
2. **احساس زنده بودن:** انیمیشن heartbeat برای القای حس موجود زنده
3. **رابط احساسی:** کاربر باید احساس کند با موجود زنده در ارتباط است

### Color Usage

- **Pistachio Green:** فقط برای حلقه لوگو و دکمه‌های خاص
- **Metal Grey:** آیکن‌های غیرفعال، border
- **Primary Black:** متن، آیکن‌های فعال
- **Background White:** پس‌زمینه

### Animation

- **Heartbeat Ring:** تپش طبیعی و جذاب (1100ms)
- **InputBar Expansion:** انیمیشن نرم هنگام باز شدن کیبورد
- **Send Icon Feedback:** تغییر رنگ سریع هنگام لمس

---

## 📝 Notes

### تغییرات اخیر (فاز 2)

1. ✅ بهینه‌سازی InputBar UI
2. ✅ اصلاح رفتار آیکن ارسال (بازخورد بصری)
3. ✅ تغییر آیکن اسپیکر از `onLongPress` به `onTap`
4. ✅ اصلاح ترتیب آیکن‌ها (mic چپ، send راست)
5. ✅ حذف opacity hacks، استفاده از رنگ‌های solid
6. ✅ بهبود انیمیشن heartbeat ring

### محدودیت‌ها

- ❌ تغییر Android native ممنوع
- ❌ تغییر iOS native ممنوع
- ❌ تغییر Backend ممنوع
- ❌ Build local امکان‌پذیر نیست

---

## 📅 تاریخچه

**فاز 2 - بهینه‌سازی UI Interactions**
- تاریخ: 2024
- تغییرات: InputBar optimization, strict color rules, tap-based voice recording

---

**تهیه شده برای:** تیم توسعه صدی  
**نسخه:** 2.0  
**وضعیت:** ✅ Production Ready

