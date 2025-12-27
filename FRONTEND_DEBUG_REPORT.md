# گزارش Debug Frontend - اتصال به Backend

**تاریخ:** 2024-12-26  
**هدف:** اطمینان از اتصال صحیح frontend به backend و حذف fallback/mock responses

---

## ✅ STEP 1: API Base URL Configuration

### Base URL
**فایل:** `frontend/lib/core/config/app_config.dart`

```dart
static const String baseUrl = "http://91.107.168.130:8000";
```

**وضعیت:** ✅ **LOCKED** - درست تنظیم شده

### Local Mode
```dart
static const bool useLocalMode = false;
```

**وضعیت:** ✅ **DISABLED** - اتصال به backend واقعی

### بررسی URLs
- ✅ هیچ `localhost` وجود ندارد
- ✅ هیچ `127.0.0.1` وجود ندارد
- ✅ هیچ `10.0.2.2` وجود ندارد
- ✅ هیچ mock URL وجود ندارد
- ✅ همه درخواست‌ها از `AppConfig.baseUrl` استفاده می‌کنند

---

## ✅ STEP 2: حذف Fallback/Mock Responses

### تغییرات انجام شده:

#### 1. حذف `_showFallbackGreeting()`
**فایل:** `frontend/lib/features/chat/state/chat_controller.dart`

**قبل:**
- تابع `_showFallbackGreeting()` greeting های hardcoded داشت:
  - "سلام! من صدی هستم..."
  - "خوشحالم که باهام صحبت می‌کنی! می‌خوای باهم بیشتر آشنا بشیم؟"
  - "خوش برگشتی..."

**بعد:**
- ✅ تابع حذف شد
- ✅ فقط error message نمایش داده می‌شود
- ✅ هیچ greeting hardcoded باقی نمانده

#### 2. تغییر `_sendGreeting()`
**قبل:**
```dart
if (backendGreeting == 'BACKEND_UNAVAILABLE') {
  _addSediMessage('...');
  await _showFallbackGreeting(); // ❌ Fallback greeting
  return;
}
```

**بعد:**
```dart
if (backendGreeting == 'BACKEND_UNAVAILABLE') {
  _addSediMessage('متأسفانه در حال حاضر به سرور متصل نیستم...');
  return; // ✅ STOP - no fallback
}
```

**وضعیت:** ✅ **تمام fallback greeting ها حذف شدند**

---

## ✅ STEP 3: Chat Request Flow

### Endpoint
**فایل:** `frontend/lib/features/chat/chat_service.dart`

```dart
path: '/interact/chat'
Method: POST
```

**وضعیت:** ✅ **درست** - همه پیام‌ها به `/interact/chat` ارسال می‌شوند

### Request Payload
```dart
queryParams = {
  'message': userMessage.trim(),
  'lang': currentLanguage,
  // Optional:
  'name': userName,
  'secret_key': userPassword,
}
```

**وضعیت:** ✅ **درست** - همه فیلدهای لازم ارسال می‌شوند

### Flow Verification
1. ✅ `sendUserMessage()` در `chat_controller.dart` فراخوانی می‌شود
2. ✅ `_chatService.sendMessage()` فراخوانی می‌شود
3. ✅ درخواست POST به `/interact/chat` ارسال می‌شود
4. ✅ هیچ short-circuit logic وجود ندارد
5. ✅ `useLocalMode` چک می‌شود اما `false` است

**وضعیت:** ✅ **همه پیام‌ها به backend ارسال می‌شوند**

---

## ✅ STEP 4: Response Parsing

### Parsing Logic
**فایل:** `frontend/lib/features/chat/chat_service.dart`

```dart
if (response.statusCode == 200) {
  final body = jsonDecode(response.body);
  final message = body['message']?.toString() ?? '';
  final userId = body['user_id'] as int?;
  
  // Return message with user_id if available
  if (userId != null && message.isNotEmpty) {
    return 'USER_ID:$userId|MESSAGE:$message';
  }
  return message;
}
```

**وضعیت:** ✅ **درست** - از `body['message']` استفاده می‌شود

### User ID Parsing
**فایل:** `frontend/lib/features/chat/state/chat_controller.dart`

```dart
String _parseResponse(String? response) {
  if (response?.startsWith('USER_ID:') == true) {
    final parts = response.split('|MESSAGE:');
    if (parts.length == 2) {
      final userIdStr = parts[0].replaceFirst('USER_ID:', '');
      final userId = int.tryParse(userIdStr);
      if (userId != null && _userProfile.userId == null) {
        _userProfile = _userProfile.copyWith(userId: userId);
        UserProfileManager.saveProfile(_userProfile);
      }
      return parts[1]; // Return clean message
    }
  }
  return response ?? '';
}
```

**وضعیت:** ✅ **درست** - user_id استخراج و ذخیره می‌شود

### Error Handling
- ✅ اگر response خالی باشد → error message نمایش داده می‌شود
- ✅ اگر parsing fail شود → error message نمایش داده می‌شود
- ✅ هیچ greeting جایگزین نمی‌شود

---

## ✅ STEP 5: Local Stage Tracking

### ConversationState Enum
**فایل:** `frontend/lib/features/chat/state/chat_controller.dart`

```dart
enum ConversationState {
  initializing,
  askingLanguage,
  chatting,
  askingName,
  askingSecurityPassword,
  verifyingSecurity,
}
```

**تحلیل:**
- این enum برای **UI state management** است (نه conversation stage)
- برای مدیریت flow در frontend (مثل نمایش dialog برای language selection)
- **Backend Conversation Brain هنوز authority است** برای conversation stage
- این state ها فقط برای UX هستند

**وضعیت:** ✅ **OK** - این state tracking برای UI است، نه conversation stage

### بررسی Stage Tracking
- ✅ هیچ `FIRST_CONTACT` loop وجود ندارد
- ✅ هیچ hardcoded stage logic وجود ندارد
- ✅ Backend Conversation Brain تصمیم می‌گیرد که چه پاسخی بدهد

---

## ✅ STEP 6: Debug Logging

### Logging اضافه شده:

#### در `ChatService.sendMessage()`:
```dart
print('[ChatService] ===== SENDING TO BACKEND =====');
print('[ChatService] URL: ${uri.toString()}');
print('[ChatService] Method: POST');
print('[ChatService] Headers: $headers');
print('[ChatService] Query params: $queryParams');
print('[ChatService] Message: "$userMessage"');

print('[ChatService] ===== BACKEND RESPONSE =====');
print('[ChatService] Status: ${response.statusCode}');
print('[ChatService] Response body: ${response.body}');
if (response.statusCode == 200) {
  print('[ChatService] ✅ SUCCESS - Backend responded');
} else {
  print('[ChatService] ❌ ERROR - Status ${response.statusCode}');
}
```

#### در `ChatController.sendUserMessage()`:
```dart
print('[ChatController] Sending message to backend: "${trimmed.substring(0, 50)}..."');
print('[ChatController] User: name=${_userProfile.name}, userId=${_userProfile.userId}, lang=$currentLanguage');
print('[ChatController] Backend response received: ${response.substring(0, 100)}...');
print('[ChatController] Parsed message to display (length: ${messageToDisplay.length})');
```

#### در `ChatController._sendGreeting()`:
```dart
print('[ChatController] Starting greeting with language: $currentLanguage');
print('[ChatController] Attempting to get greeting from backend...');
print('[ChatController] Backend greeting received: ${backendGreeting != null ? "Yes" : "No"}');
print('[ChatController] Using backend greeting (length: ${backendGreeting.length})');
print('[ChatController] ERROR: Backend unavailable - showing error state only');
```

**وضعیت:** ✅ **Debug logging اضافه شد** (TEMPORARY - برای verification)

---

## 📋 خلاصه تغییرات

### فایل‌های تغییر یافته:

1. **`frontend/lib/features/chat/state/chat_controller.dart`**
   - ✅ حذف `_showFallbackGreeting()`
   - ✅ تغییر `_sendGreeting()` - فقط error نشان می‌دهد
   - ✅ اضافه کردن debug logging
   - ✅ بهبود error handling

2. **`frontend/lib/features/chat/chat_service.dart`**
   - ✅ اضافه کردن debug logging
   - ✅ بهبود logging برای request/response

### فایل‌های بررسی شده (بدون تغییر):

- ✅ `frontend/lib/core/config/app_config.dart` - Base URL درست است
- ✅ `frontend/lib/core/network/api_client.dart` - خالی است (استفاده نمی‌شود)
- ✅ `frontend/lib/features/notification/data/notification_service.dart` - از AppConfig استفاده می‌کند

---

## ✅ Final Verification

### 1. Base URL
- ✅ **LOCKED:** `http://91.107.168.130:8000`
- ✅ هیچ localhost/mock URL وجود ندارد

### 2. Fallback Responses
- ✅ **حذف شدند:** تمام fallback greeting ها
- ✅ فقط error messages نمایش داده می‌شوند

### 3. Chat Request Flow
- ✅ **همه پیام‌ها** به `/interact/chat` ارسال می‌شوند
- ✅ هیچ short-circuit logic وجود ندارد

### 4. Response Parsing
- ✅ از `body['message']` استفاده می‌شود
- ✅ user_id استخراج و ذخیره می‌شود
- ✅ هیچ greeting جایگزین نمی‌شود

### 5. Local Stage Tracking
- ✅ ConversationState فقط برای UI است
- ✅ Backend Conversation Brain authority است

### 6. Debug Logging
- ✅ Logging اضافه شد (TEMPORARY)

---

## 🎯 پاسخ به سوالات نهایی

### 1) Base URL used (exact string)
**پاسخ:** `http://91.107.168.130:8000`

### 2) Files modified (list)
1. `frontend/lib/features/chat/state/chat_controller.dart`
2. `frontend/lib/features/chat/chat_service.dart`

### 3) All fallbacks removed? (yes/no)
**پاسخ:** ✅ **YES**
- `_showFallbackGreeting()` حذف شد
- تمام greeting های hardcoded حذف شدند
- فقط error messages باقی مانده

### 4) Does every message hit backend? (yes/no)
**پاسخ:** ✅ **YES**
- همه پیام‌ها از `sendUserMessage()` به `_chatService.sendMessage()` می‌روند
- `useLocalMode = false` - هیچ mock response استفاده نمی‌شود
- همه درخواست‌ها به `/interact/chat` ارسال می‌شوند

### 5) Do responses change per interaction? (yes/no)
**پاسخ:** ✅ **YES**
- Backend Conversation Brain تصمیم می‌گیرد
- Frontend فقط response را نمایش می‌دهد
- هیچ caching یا hardcoded response وجود ندارد

---

## ✅ نتیجه‌گیری

**وضعیت:** ✅ **تمام مراحل تکمیل شد**

- ✅ Base URL locked
- ✅ Fallbacks removed
- ✅ All messages hit backend
- ✅ Responses come from backend
- ✅ Debug logging added

**آماده برای تست:** ✅ بله

---

**نکته:** Debug logging ها TEMPORARY هستند و باید بعد از verification حذف شوند.

