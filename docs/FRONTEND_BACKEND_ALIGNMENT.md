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

#### OTP Auth (Stage 25)

- `POST /auth/request_otp`
  - Request body: `{ "phone": "string" }`
  - Header (optional): `Accept-Language: en|fa|ar`
  - Response envelope:
    - success: `{ "ok": true, "data": { "ok": true, "next": "verify_otp" }, "error": null }`
    - error: `{ "ok": false, "data": null, "error": { "code": "OTP_REQUEST_FAILED", "message": "..." } }`
- `POST /auth/verify_otp`
  - Request body: `{ "phone": "string", "code": "string(6)" }`
  - Header (optional audit): `X-Device-Info`, `X-Client-IP`
  - Response envelope:
    - success: `{ "ok": true, "data": { "access_token": "...", "refresh_token": "...", "token_type": "bearer", "expires_in": 3600 }, "error": null }`
    - error codes: `OTP_INVALID`, `OTP_EXPIRED`, `TOO_MANY_ATTEMPTS`

---

### ۳.۲ تعامل (چت، معرفی، onboarding)

| متد | مسیر کامل | Request | Response | وضعیت فرانت |
|-----|-----------|---------|----------|-------------|
| POST | `/interact/introduce` | name, ... | InteractionResponse | دارد |
| POST | `/interact/chat` | `ChatRequest`: `user_id` (required), `message` (required) | `InteractionResponse`: `message`, `language`, `user_id?`, `timestamp`, `requires_security_check?`, `detected_name?` | دارد |
| POST | `/interact/onboarding` | OnboardingRequest (name) | - | دارد |
| GET | `/interact/greeting` | - | - | بررسی شود |
| GET | `/interact/history` | query: `user_id` (required), `limit` (1..50) | `{ user_id, messages[] }` | دارد |

**InteractionResponse (بک‌اند):** `message`, `language`, `user_id`, `timestamp`, `requires_security_check`, `detected_name`.  
**فرانت:** `data/dto/interact_request.dart`, `interact_response.dart`, `repositories/chat_repository.dart`.

#### Chat Contract (V1 exact)

- **Send message**
  - `POST /interact/chat`
  - Body (required): `{ "user_id": int, "message": string }`
  - Header: `Authorization: Bearer <token>` (preferred in frontend), `Accept-Language` (supported by backend language resolver)
  - Success `200` body (non-envelope on this route): `InteractionResponse`
    - `message`, `language`, `user_id`, `timestamp`, optional `requires_security_check`, optional `detected_name`
  - Errors:
    - `400`: empty message / invalid user_id
    - `404`: user not found
    - `502`: GPT/provider failure (`{ error: "gpt_failure", detail: ... }`)
    - `500`: internal processing error
- **Chat history**
  - `GET /interact/history?user_id={id}&limit={n}`
  - Latest first (`created_at desc`)
  - Response: `{ "user_id": int, "messages": [{ id, user_message, sedi_response, language, created_at }] }`
- **Extended history (grouped UI history)**
  - `GET /memory/history?user_id={id}&group=daily|weekly|monthly|yearly&limit&offset`
  - Returns grouped items (`HistoryResponse`) with group pagination by bucket, not cursor.

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
| GET | `/lifestyle/context` | query: `user_id` (required) | `APIResponse` with MemoryContext keys | دارد |
| POST | `/lifestyle/update` | `LifestyleUpdateRequest` | `APIResponse` | دارد |
| GET | `/lifestyle/summary` | query: `user_id` (required), `lang` (optional) | `APIResponse` summary payload | دارد |

**LifestyleUpdateRequest (exact backend contract):**
- `user_id: int` (required)
- `entries: LifestyleEntry[]` (required)
  - `domain: string` (e.g. `lifestyle`)
  - `key: string` (e.g. `sleep_duration_hours`, `hydration_ml`, `steps_count`, `exercise_minutes`, `mood`, `stress_level`, `activity_level`, `sleep_quality`)
  - `value: any`
  - `confidence: float (0..1)` default `0.7`
  - `source: string` default `manual`

**GET /lifestyle/context -> data keys (MemoryContext):**
- `sleep_duration_hours`, `sleep_quality`
- `hydration_ml`
- `activity_level`, `steps_count`, `exercise_minutes`
- `mood`, `stress_level`

**Envelope format:** all lifestyle endpoints use standard `{ ok, data, error }`.

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

#### Notification Inbox Contract (V1)

- `GET /notifications?user_id={id}`
  - Query: `user_id` (required)
  - Sorting: `created_at desc` (latest first)
  - Response data:
    - `notifications`: array of `{ id, user_id, type, title, body, priority, is_read, is_sent, scheduled_for, created_at }`
    - `total`, `unread_count`
  - Pagination: currently none in backend list endpoint (returns full list for user)
- `GET /notifications/unread?user_id={id}&limit={n}&type={optional}`
  - Query: `user_id` required, `limit` optional (default 20, max 100), `type` optional
  - Response data:
    - `notifications` (unread only, latest first), `count`, `total`, `unread_count`
- `POST /notifications/{notification_id}/mark-read?user_id={id}`
  - Idempotent mark-read endpoint
  - Response data: `{ ok: true, notification_id, is_read: true }`
- `POST /notifications/{notification_id}/feedback?user_id={optional}`
  - Accepts contract/legacy payload; frontend can send:
    - `{ reaction: "like"|"dislike", timestamp: ISO8601, feedback: "positive"|"negative" }`
  - Response data: feedback recorded confirmation
- Envelope for all above remains backend standard:
  - success: `{ ok: true, data: ... , error: null }`
  - failure: `{ ok: false, data: null, error: { code, message } }`

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

#### Heart Rate / Health Alerts (V1)

- **Heart-rate event ingest exists, listing does not exist (currently)**
  - `POST /device/ingest` with `event_type = "heart_rate"` and payload like `{ "bpm": 82, "quality": "good" }`
  - Stored in `device_events` model fields: `id`, `user_id`, `device_id`, `event_type`, `payload_json`, `recorded_at`, `received_at`, `dedupe_key`
  - There is **no public read endpoint** for listing `device_events` by `user_id` in current included routers.
- **Other health writes**
  - `POST /health/add` writes to `health_data` and may create notifications.
  - `POST /device_data/data/upload` (router not included in `main.py`) writes `health_data` and `lifestyle_data`.
- **Health alerts source**
  - Implemented via notifications contract (`/notifications` + `/notifications/unread`), using `type/channel/priority` fields.
  - Preferred filter: `type/channel == "health_alert"`; fallbacks: `priority in {high, critical}` or localized title heuristics.
- **Frontend TODO marker**
  - When backend adds a read endpoint (example target: `GET /device/events?user_id=&event_type=heart_rate&limit=`), switch heart-rate list from notifications proxy to real device events.

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
