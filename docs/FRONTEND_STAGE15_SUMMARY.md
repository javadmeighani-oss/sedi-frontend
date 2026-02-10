# جمع‌بندی Stage 15.2 تا 15.5 (یکجا)

**تاریخ:** ۲۰۲۵-۰۲-۰۹  
**مرجع:** `frontend/docs/FRONTEND_BACKEND_ALIGNMENT.md`  
**مسیر گزارش تفصیلی:** `docs/FRONTEND_STAGE15_REPORT.md`

---

## ۱) هدف کلی

هم‌راستا کردن لایهٔ دادهٔ فرانت با بک‌اند:

- پاسخ استاندارد `{ ok, data, error }` و یک ApiClient یکپارچه
- DTO و Repository برای **سلامت**، **اعلان‌ها**، و **دستگاه‌ها**
- بدون UI در این مرحله؛ فقط لایهٔ داده + دیباگهای گارد شده

---

## ۲) خلاصه هر استیج

| استیج | هدف | خروجی اصلی |
|--------|-----|-------------|
| **15.2** | ApiResponse + ApiClient | مدل‌های `ApiError` و `ApiResponse<T>`؛ کلاینت با `get`/`post` و مدیریت خطا؛ NotificationService روی ApiClient؛ رفع فراخوانی‌های `setupOnboarding` (پارامتر `name`). |
| **15.3** | سلامت (ویتال) | DTOهای `HealthDataCreate` و `HealthDataResponse`؛ `HealthRepository.addHealthData`؛ دیباگ `smokeHealthAdd()`. |
| **15.4** | اعلان‌ها (قرارداد کامل) | مدل واحد Notification با پارس بک‌اند؛ `fetchUnreadList`، `markRead`؛ فیدبک با `toBackendJson()` (positive/negative/neutral)؛ رفع تداخل با Flutter `Notification`. |
| **15.5** | دستگاه‌ها و ingest | DTOهای register/list/ingest؛ `DevicesRepository` (register, list, revoke, rotateToken) و `DeviceRepository` (ingest)؛ دیباگ `smokeDevices()` و `smokeDeviceIngest()`. |

---

## ۳) فایل‌های اضافه/تغییر یافته (یکجا)

### core/network
| فایل | نوع | توضیح |
|------|-----|--------|
| `lib/core/network/api_error.dart` | جدید | خطای بک‌اند: `code?`, `message`. |
| `lib/core/network/api_response.dart` | جدید | `ApiResponse<T>` با `fromJson(json, parser)`. |
| `lib/core/network/api_client.dart` | جدید | GET/POST با `queryParams`؛ هدر توکن؛ نگاشت خطا به `ApiResponse(ok: false)`. |

### core/debug
| فایل | نوع | توضیح |
|------|-----|--------|
| `lib/core/debug/smoke_health.dart` | جدید | ارسال ویتال نمونه برای کاربر جاری (گارد شده). |
| `lib/core/debug/smoke_devices.dart` | جدید | ثبت دستگاه نمونه + لیست (گارد شده). |
| `lib/core/debug/smoke_device_ingest.dart` | جدید | ارسال رویداد نمونه ingest (گارد شده). |

### data/dto
| فایل | نوع | توضیح |
|------|-----|--------|
| `lib/data/dto/health_data_create.dart` | جدید | درخواست POST /health/add. |
| `lib/data/dto/health_data_response.dart` | جدید | پاسخ (health_id, user_id, message و غیره). |
| `lib/data/dto/device_register_request.dart` | جدید | درخواست ثبت دستگاه. |
| `lib/data/dto/device_public_info.dart` | جدید | آیتم لیست دستگاه. |
| `lib/data/dto/devices_list_response.dart` | جدید | لیست دستگاه‌ها + count. |
| `lib/data/dto/device_ingest_request.dart` | جدید | درخواست POST /device/ingest. |
| `lib/data/dto/device_ingest_response.dart` | جدید | پاسخ ingest (event_id, dedupe_key). |

### data/repositories
| فایل | نوع | توضیح |
|------|-----|--------|
| `lib/data/repositories/health_repository.dart` | جدید | `addHealthData`. |
| `lib/data/repositories/devices_repository.dart` | جدید | register, list, revoke, rotateToken. |
| `lib/data/repositories/device_repository.dart` | جدید | ingest. |

### data/models + features/notification
| فایل | نوع | توضیح |
|------|-----|--------|
| `lib/data/models/notification.dart` | به‌روز | پارس بک‌اند (body، نوع‌ها، critical→urgent). |
| `lib/data/models/notification_feedback.dart` | به‌روز | `toBackendJson()` برای فیدبک. |
| `lib/features/notification/data/models/sedi_notification.dart` | به‌روز | re-export مدل واحد. |
| `lib/features/notification/data/notification_service.dart` | به‌روز | ApiClient؛ fetchUnreadList، markRead؛ submitFeedback با URL و body درست. |
| `lib/features/notification/presentation/widgets/notification_card.dart` | به‌روز | import با پیشوند `sedi`؛ مسیر درست. |
| `lib/features/notification/logic/frontend_contract_test.dart` | به‌روز | total/unread_count اختیاری. |
| `lib/features/notification/logic/notification_test.dart` | به‌روز | `isSedi: true`. |

### سایر
| فایل | نوع | توضیح |
|------|-----|--------|
| `lib/features/user_verification/.../user_verification_page.dart` | به‌روز | `name` در setupOnboarding. |
| `lib/features/chat/chat_service.dart` | به‌روز | `name: userName` در registerUser. |

### test
| فایل | نوع | توضیح |
|------|-----|--------|
| `test/api_response_test.dart` | جدید | ApiError و ApiResponse. |
| `test/health_data_test.dart` | جدید | HealthDataCreate/Response. |
| `test/notification_contract_test.dart` | جدید | Notification و NotificationFeedback. |
| `test/device_dto_test.dart` | جدید | DTOهای device/devices. |

---

## ۴) تست‌ها و Verify (جمع)

| دستور | نتیجه |
|--------|--------|
| `flutter analyze` روی فایل‌های Stage 15 | بدون خطا (برای همان فایل‌ها). |
| `flutter test test/api_response_test.dart` | ۷/۷ پاس. |
| `flutter test test/health_data_test.dart` | ۴/۴ پاس. |
| `flutter test test/notification_contract_test.dart` | ۷/۷ پاس. |
| `flutter test test/device_dto_test.dart` | ۶/۶ پاس. |
| `flutter test` (کل پروژه) | یک شکست از قبل: **widget_test** (تایمر IntroPage). |

---

## ۵) چک‌لیست نهایی (15.2–15.5)

- [x] **ApiResponse&lt;T&gt;** و **ApiError**؛ ApiClient با GET/POST و queryParams.
- [x] NotificationService روی ApiClient؛ قرارداد اعلان (unread، mark-read، feedback با positive/negative/neutral).
- [x] مدل واحد Notification؛ فیدبک با toBackendJson.
- [x] HealthData DTO و HealthRepository؛ smoke_health.
- [x] Devices/Device DTO و دو ریپازیتوری؛ smoke_devices و smoke_device_ingest.
- [x] تست‌های واحد برای همهٔ DTOها و ApiResponse؛ گزارش به‌روز.

---

## ۶) APIهای پوشش‌داده‌شده

| Endpoint | استیج | وضعیت |
|----------|--------|--------|
| (فرمت پاسخ استاندارد) | 15.2 | ApiResponse&lt;T&gt; در همهٔ درخواست‌ها |
| POST /health/add | 15.3 | HealthRepository.addHealthData |
| GET /notifications، GET /notifications/unread | 15.4 | getNotifications، fetchUnreadList |
| POST /notifications/{id}/mark-read | 15.4 | markRead |
| POST /notifications/{id}/feedback | 15.4 | submitFeedback با toBackendJson |
| POST /devices/register، GET /devices | 15.5 | DevicesRepository.register، list |
| POST /devices/{id}/revoke، POST /devices/{id}/rotate-token | 15.5 | revoke، rotateToken |
| POST /device/ingest | 15.5 | DeviceRepository.ingest |

برای جزئیات هر استیج به **FRONTEND_STAGE15_REPORT.md** مراجعه کنید.
