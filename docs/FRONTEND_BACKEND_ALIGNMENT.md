# هم‌راستایی فرانت‌اند با بک‌اند Sedi

**هدف:** سند مرجع برای بازنویسی و توسعهٔ فرانت بر اساس API و اسکیماهای بک‌اند.  
**بک‌اند:** FastAPI، نسخه ۲.۰.۱، Entrypoint: `backend.app.main:app`  
**فرانت‌اند:** Flutter، مسیر: `frontend/lib`

---

## ۱) فرمت پاسخ استاندارد بک‌اند

اکثر endpointها با این ساختار پاسخ می‌دهند:

```json
{
  "ok": true,
  "data": { ... },
  "error": null
}
```

یا در صورت خطا:

```json
{
  "ok": false,
  "data": null,
  "error": {
    "code": "optional_code",
    "message": "متن خطا"
  }
}
```

**در فرانت:** یک مدل مشترک مثلاً `ApiResponse<T>` با فیلدهای `ok`, `data`, `error` توصیه می‌شود؛ DTOهای دامنه داخل `data` قرار می‌گیرند.

---

## ۲) APIهای متصل در main (فعال)

این روت‌ها در `backend/app/main.py` include شده‌اند و در دسترس هستند.

| پیشوند | فایل روتر | توضیح |
|--------|-----------|--------|
| `/auth` | auth.py | احراز هویت (passkey) |
| `/auth/login` | auth_login.py | درخواست/تأیید PIN، refresh token |
| `/interact` | interact.py | معرفی، چت، onboarding، greeting، history |
| `/health` | health.py | داده سلامتی |
| `/lifestyle` | lifestyle.py | سبک زندگی |
| `/notifications` | notifications.py | لیست، unread، mark-read، feedback، deliver_pending |
| `/ai_core` | ai_core.py | تحلیل با AI |
| `/conditions` | conditions.py | شرایط پزشکی و UserCondition |
| `/device` | device.py | ingest رویداد دستگاه، heartbeat، pending-commands |
| `/devices` | devices.py | ثبت/لیست/revoke/rotate دستگاه |
| `/decision` | decision.py | موتور تصمیم‌گیری (evaluate) |

---

## ۳) endpointها و اسکیما (برای هر دامنه)

### ۳.۱ احراز هویت

| متد | مسیر کامل | Request (Backend) | Response | وضعیت فرانت |
|-----|-----------|-------------------|----------|-------------|
| POST | `/auth/set-passkey` | - | APIResponse | بررسی شود |
| POST | `/auth/verify-passkey` | - | APIResponse | بررسی شود |
| POST | `/auth/login/request-pin` | - | APIResponse | دارد (auth_service) |
| POST | `/auth/login/verify-pin` | - | APIResponse (حاوی token) | دارد |
| POST | `/auth/login/refresh-token` | - | APIResponse | دارد |
| GET | `/auth/login/verify-token` | - | APIResponse | دارد |

**اسکیماهای بک‌اند:** `backend/app/schemas/user.py` (UserCreate, UserResponse).  
**فرانت:** `core/auth/auth_service.dart`, `auth_helper.dart`.

---

### ۳.۲ تعامل (چت، معرفی، onboarding)

| متد | مسیر کامل | Request | Response | وضعیت فرانت |
|-----|-----------|---------|----------|-------------|
| POST | `/interact/introduce` | name, ... | InteractionResponse | دارد |
| POST | `/interact/chat` | user_id, message (ChatRequest) | InteractionResponse | دارد (chat_repository) |
| POST | `/interact/onboarding` | OnboardingRequest (name) | - | دارد |
| GET | `/interact/greeting` | - | - | بررسی شود |
| GET | `/interact/history` | - | - | دارد |

**InteractionResponse (بک‌اند):** `message`, `language`, `user_id`, `timestamp`, `requires_security_check`, `detected_name`.  
**فرانت:** `data/dto/interact_request.dart`, `interact_response.dart`, `repositories/chat_repository.dart`.

---

### ۳.۳ سلامت

| متد | مسیر کامل | Request | Response | وضعیت فرانت |
|-----|-----------|---------|----------|-------------|
| POST | `/health/add` | HealthDataCreate | APIResponse | **نیاز به DTO و سرویس** |

**HealthDataCreate:** `user_id`, `heart_rate?`, `temperature?`, `spo2?`.  
**HealthDataResponse:** `id`, `user_id`, `heart_rate`, `temperature`, `spo2`, `created_at`.

---

### ۳.۴ سبک زندگی

| متد | مسیر کامل | Request | Response | وضعیت فرانت |
|-----|-----------|---------|----------|-------------|
| POST | `/lifestyle/update` | LifestyleDataCreate | APIResponse | **نیاز به DTO و سرویس** |
| GET | `/lifestyle/context` | - | APIResponse | **نیاز به سرویس** |

**LifestyleDataCreate:** `user_id`, `sleep_hours?`, `steps?`, `calories?`, `stress_level?`.

---

### ۳.۵ اعلان‌ها

| متد | مسیر کامل | Request | Response | وضعیت فرانت |
|-----|-----------|---------|----------|-------------|
| GET | `/notifications` یا `/notifications/` | - | APIResponse (لیست) | دارد (notification_service) |
| GET | `/notifications/unread` | - | APIResponse | بررسی شود |
| POST | `/notifications/{id}/mark-read` | - | APIResponse | بررسی شود |
| POST | `/notifications/{id}/read` | - | APIResponse (alias) | - |
| POST | `/notifications/{id}/feedback` | NotificationFeedbackRequest | APIResponse | دارد |
| POST | `/notifications/deliver_pending` | - | APIResponse | معمولاً از بک‌اند/سcheduler |

**Notification (پاسخ):** `id`, `user_id`, `type`, `title`, `body`, `priority`, `is_read`, `is_sent`, `created_at`, `scheduled_for`.  
**NotificationFeedbackRequest:** `feedback` (positive|negative|neutral), `reason?`, `action?`.  
**نوع اعلان (ثابت):** `morning_brief` | `connection_ping` | `health_alert` | `device_disconnected`.  
**فرانت:** `features/notification/`, `data/models/notification.dart`, `notification_feedback.dart`.

---

### ۳.۶ AI Core

| متد | مسیر کامل | Request | Response | وضعیت فرانت |
|-----|-----------|---------|----------|-------------|
| POST | `/ai_core/analyze` | - | APIResponse | **نیاز به سرویس** |

---

### ۳.۷ شرایط پزشکی

| متد | مسیر کامل | Request | Response | وضعیت فرانت |
|-----|-----------|---------|----------|-------------|
| GET | `/conditions` | - | APIResponse (لیست شرایط) | **نیاز به DTO و سرویس** |
| GET | `/conditions/user/{user_id}` | - | APIResponse | **نیاز به سرویس** |
| POST | `/conditions/assign` | - | APIResponse | **نیاز به سرویس** |
| DELETE | `/conditions/user/{user_id}/condition/{condition_id}` | - | APIResponse | **نیاز به سرویس** |

---

### ۳.۸ دستگاه (Device) – ingest و کنترل

| متد | مسیر کامل | Request | Response | وضعیت فرانت |
|-----|-----------|---------|----------|-------------|
| GET | `/device/pending-commands` | - | APIResponse | **نیاز به سرویس (اختیاری)** |
| POST | `/device/heartbeat` | - | APIResponse | **نیاز به سرویس** |
| POST | `/device/acknowledge` | - | APIResponse | **نیاز به سرویس** |
| POST | `/device/ingest` | DeviceIngestRequest | DeviceIngestResponse | **نیاز به DTO و سرویس** |

**DeviceIngestRequest:** `user_id`, `device_id?`, `event_type` (heart_rate|blood_pressure|glucose|temperature), `payload` (map), `recorded_at?`.

---

### ۳.۹ دستگاه‌ها (Devices) – ثبت و مدیریت

| متد | مسیر کامل | Request | Response | وضعیت فرانت |
|-----|-----------|---------|----------|-------------|
| POST | `/devices/register` | DeviceRegisterRequest | DeviceRegisterResponse | **نیاز به DTO و سرویس** |
| GET | `/devices` | - | DevicesListResponse | **نیاز به سرویس** |
| POST | `/devices/{device_id}/revoke` | - | DeviceRegisterResponse | **نیاز به سرویس** |
| POST | `/devices/{device_id}/rotate-token` | - | DeviceRegisterResponse | **نیاز به سرویس** |

**DeviceRegisterRequest:** `device_id`, `device_type?` (پیش‌فرض heart_rate).  
**DevicePublicInfo:** `device_id`, `device_type`, `status` (active|revoked), `last_seen_at`, `created_at`, `revoked_at`.

---

### ۳.۱۰ Decision (موتور تصمیم)

| متد | مسیر کامل | Request | Response | وضعیت فرانت |
|-----|-----------|---------|----------|-------------|
| POST | `/decision/evaluate` | - | - | **معمولاً داخلی بک‌اند؛ در صورت نیاز فرانت** |

---

## ۴) روترهای تعریف‌شده ولی بدون include در main

این روترها در کد بک‌اند وجود دارند ولی در `main.py` include نشده‌اند. در صورت اضافه شدن به main، فرانت می‌تواند برایشان سرویس/DTO آماده کند:

- **data.py** → `POST /data/upload`
- **device_data.py** → `POST /device_data/data/upload`
- **medical.py** → `POST /medical/share`, `GET /medical/records`, `POST /medical/doctor-note`
- **memory.py** → `POST /memory/save`, `GET /memory/latest`
- **sms_gateway.py** → `POST /sms_gateway/send`, `GET /sms_gateway/logs`

---

## ۵) خلاصه وضعیت فرانت نسبت به بک‌اند

| دامنه | فرانت دارد | فرانت نیاز دارد |
|-------|------------|------------------|
| Auth / Login | auth_service، request-pin، verify-pin، refresh، verify-token | هم‌راستایی با set/verify-passkey در صورت استفاده |
| Interact | introduce، chat، onboarding، history، DTOها | اطمینان از greeting و تطابق InteractionResponse |
| Health | - | HealthDataCreate/Response، repository یا service، UI |
| Lifestyle | - | LifestyleDataCreate/Response، repository یا service، UI |
| Notifications | لیست، feedback، مدل اعلان | unread، mark-read، تطابق type و feedback با قرارداد بک‌اند |
| AI Core | - | سرویس برای /ai_core/analyze |
| Conditions | - | DTOها، سرویس، UI (لیست شرایط، assign، حذف) |
| Device (ingest) | - | DeviceIngestRequest/Response، سرویس (احراز هویت دستگاه در هدر) |
| Devices (مدیریت) | - | DeviceRegisterRequest، DevicePublicInfo، سرویس ثبت/لیست/revoke/rotate |

---

## ۶) پیشنهاد ساختار فرانت برای توسعه

- **core/network:** یک **ApiClient** واحد با متدهای GET/POST و پشتیبانی از توکن (مثلاً از auth_service). پاسخ‌ها به `ApiResponse<T>` پارس شوند.
- **data/dto:** برای هر دامنه (health، lifestyle، device، devices، conditions، notification) DTOهای request/response مطابق اسکیماهای بک‌اند.
- **data/repositories:** مثلاً `health_repository.dart`, `lifestyle_repository.dart`, `devices_repository.dart`, `conditions_repository.dart` که از ApiClient استفاده کنند.
- **features:** هر feature (مثلاً health، lifestyle، conditions، devices) می‌تواند شامل `data/`, `logic/`, `presentation/` باشد و از repository مربوطه استفاده کند.

با این سند می‌توان در پرامپت‌های بعدی به‌طور مشخص اشاره کرد که «بر اساس `frontend/docs/FRONTEND_BACKEND_ALIGNMENT.md` فلان endpoint و DTO را اضافه کن» یا «صفحه سلامت را با HealthDataCreate هم‌راستا کن».
