# 🔌 مستندات API صدی

## 📡 آدرس پایه (Base URL)

```
http://91.107.168.130:8000
```

---

## 🔐 احراز هویت (Authentication)

### روش:
تمام درخواست‌ها (به جز لاگین) نیاز به توکن JWT دارند که در هدر `Authorization` ارسال می‌شود.

### فرمت:
```
Authorization: Bearer <token>
```

### دریافت توکن:
```http
POST /auth/login
Content-Type: application/json

{
  "username": "user@example.com",
  "password": "password123"
}
```

### پاسخ موفق:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 3600
}
```

---

## 💬 چت (Chat)

### ارسال پیام

#### درخواست:
```http
POST /chat
Content-Type: application/json
Authorization: Bearer <token>

{
  "message": "سلام صدی"
}
```

#### پاسخ موفق (200):
```json
{
  "reply": "سلام! چطور می‌تونم کمکت کنم؟",
  "session_id": "abc123",
  "metadata": {
    "timestamp": "2024-01-01T12:00:00Z",
    "confidence": 0.95
  }
}
```

#### پاسخ خطا (400):
```json
{
  "Message": "پیام خالی است",
  "error_code": "EMPTY_MESSAGE"
}
```

#### پاسخ خطا (401):
```json
{
  "Message": "Unauthorized",
  "error_code": "UNAUTHORIZED"
}
```

#### پاسخ خطا (500):
```json
{
  "Message": "خطای داخلی سرور",
  "error_code": "INTERNAL_ERROR"
}
```

---

## 👤 کاربر (User)

### دریافت پروفایل

#### درخواست:
```http
GET /user/profile
Authorization: Bearer <token>
```

#### پاسخ موفق (200):
```json
{
  "id": "user123",
  "name": "احمد",
  "email": "ahmad@example.com",
  "language": "fa",
  "created_at": "2024-01-01T00:00:00Z"
}
```

### به‌روزرسانی پروفایل

#### درخواست:
```http
PUT /user/profile
Content-Type: application/json
Authorization: Bearer <token>

{
  "name": "احمد جدید",
  "language": "en"
}
```

#### پاسخ موفق (200):
```json
{
  "id": "user123",
  "name": "احمد جدید",
  "email": "ahmad@example.com",
  "language": "en",
  "updated_at": "2024-01-01T12:00:00Z"
}
```

---

## 📜 تاریخچه چت (Chat History)

### دریافت تاریخچه

#### درخواست:
```http
GET /chat/history?page=1&limit=20
Authorization: Bearer <token>
```

#### Query Parameters:
- `page` (optional): شماره صفحه (پیش‌فرض: 1)
- `limit` (optional): تعداد پیام‌ها در هر صفحه (پیش‌فرض: 20)

#### پاسخ موفق (200):
```json
{
  "messages": [
    {
      "id": "msg1",
      "text": "سلام",
      "is_user": true,
      "timestamp": "2024-01-01T10:00:00Z"
    },
    {
      "id": "msg2",
      "text": "سلام! چطور می‌تونم کمکت کنم؟",
      "is_user": false,
      "timestamp": "2024-01-01T10:00:01Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "total_pages": 5
  }
}
```

---

## 🔔 اعلان‌ها (Notifications)

### دریافت اعلان‌ها

#### درخواست:
```http
GET /notifications
Authorization: Bearer <token>
```

#### پاسخ موفق (200):
```json
{
  "notifications": [
    {
      "id": "notif1",
      "title": "یادآوری",
      "body": "زمان مصرف دارو فرا رسیده است",
      "type": "reminder",
      "read": false,
      "timestamp": "2024-01-01T12:00:00Z"
    }
  ]
}
```

### علامت‌گذاری به عنوان خوانده شده

#### درخواست:
```http
PUT /notifications/{id}/read
Authorization: Bearer <token>
```

#### پاسخ موفق (200):
```json
{
  "id": "notif1",
  "read": true
}
```

---

## 🎤 Voice Input (پیشنهادی برای آینده)

### آپلود فایل صوتی

#### درخواست:
```http
POST /chat/voice
Content-Type: multipart/form-data
Authorization: Bearer <token>

file: <audio_file>
```

#### پاسخ موفق (200):
```json
{
  "transcription": "متن تبدیل شده از صدا",
  "reply": "پاسخ صدی",
  "session_id": "abc123"
}
```

---

## 📊 کدهای وضعیت HTTP

| کد | معنی | توضیح |
|---|---|---|
| 200 | OK | درخواست موفق |
| 201 | Created | ایجاد موفق |
| 400 | Bad Request | درخواست نامعتبر |
| 401 | Unauthorized | نیاز به احراز هویت |
| 403 | Forbidden | دسترسی ممنوع |
| 404 | Not Found | یافت نشد |
| 500 | Internal Server Error | خطای سرور |

---

## 🔄 مدیریت خطا

### فرمت خطا:
```json
{
  "Message": "توضیح خطا",
  "error_code": "ERROR_CODE",
  "details": {
    "field": "توضیحات بیشتر"
  }
}
```

### کدهای خطای رایج:

| کد | معنی |
|---|---|
| `EMPTY_MESSAGE` | پیام خالی است |
| `UNAUTHORIZED` | نیاز به احراز هویت |
| `INVALID_TOKEN` | توکن نامعتبر |
| `RATE_LIMIT_EXCEEDED` | تعداد درخواست‌ها بیش از حد |
| `INTERNAL_ERROR` | خطای داخلی سرور |

---

## ⏱️ Rate Limiting

### محدودیت‌ها:
- **Chat**: 60 درخواست در دقیقه
- **Profile**: 10 درخواست در دقیقه
- **History**: 30 درخواست در دقیقه

### هدرهای پاسخ:
```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 59
X-RateLimit-Reset: 1640000000
```

---

## 🔒 امنیت

### بهترین روش‌ها:
1. **همیشه از HTTPS استفاده کنید** (در production)
2. **توکن را امن نگه دارید** (استفاده از secure storage)
3. **توکن را به‌روزرسانی کنید** قبل از انقضا
4. **از Certificate Pinning استفاده کنید** (اختیاری)

---

## 📝 مثال‌های کامل

### مثال 1: ارسال پیام ساده
```dart
final url = Uri.parse('${AppConfig.baseUrl}/chat');
final headers = {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $token',
};
final body = jsonEncode({'message': 'سلام'});

final response = await http.post(url, headers: headers, body: body);

if (response.statusCode == 200) {
  final data = jsonDecode(response.body);
  print(data['reply']);
}
```

### مثال 2: دریافت پروفایل
```dart
final url = Uri.parse('${AppConfig.baseUrl}/user/profile');
final headers = {
  'Authorization': 'Bearer $token',
};

final response = await http.get(url, headers: headers);

if (response.statusCode == 200) {
  final data = jsonDecode(response.body);
  final user = UserProfile.fromJson(data);
  print(user.name);
}
```

### مثال 3: مدیریت خطا
```dart
try {
  final response = await http.post(url, headers: headers, body: body);
  
  if (response.statusCode == 200) {
    // موفق
  } else if (response.statusCode == 401) {
    // نیاز به لاگین مجدد
    await AuthService.clearToken();
    // هدایت به صفحه لاگین
  } else {
    // خطای دیگر
    final error = jsonDecode(response.body);
    throw Exception(error['Message']);
  }
} on SocketException {
  // خطای شبکه
  throw Exception('عدم اتصال به اینترنت');
} catch (e) {
  // خطای دیگر
  throw Exception('خطا: $e');
}
```

---

## 🧪 تست API

### استفاده از Postman/Insomnia:

1. **ایجاد Collection جدید**
2. **تنظیم Base URL**: `http://91.107.168.130:8000`
3. **تنظیم Authorization**: Bearer Token
4. **ایجاد Request های مختلف**

### مثال Request در Postman:
```
POST http://91.107.168.130:8000/chat
Headers:
  Content-Type: application/json
  Authorization: Bearer YOUR_TOKEN
Body (JSON):
{
  "message": "سلام"
}
```

---

## 📞 پشتیبانی

برای سوالات و مشکلات API:
- بررسی مستندات
- تماس با تیم بک‌اند
- ایجاد Issue در GitHub

---

**آخرین به‌روزرسانی**: 2024
**نسخه API**: 1.0.0

