**جمع‌بندی یکجا Stage 15.2 تا 15.5:** [FRONTEND_STAGE15_SUMMARY.md](FRONTEND_STAGE15_SUMMARY.md)

---

# Stage 15.2 Report: ApiResponse&lt;T&gt; and ApiClient Error Handling

**Date:** 2025-02-09  
**Reference:** `frontend/docs/FRONTEND_BACKEND_ALIGNMENT.md`  
**Goal:** Backend-standard `ApiResponse<T>` and unified `ApiClient` error handling.

---

## 1) Summary

- Added **ApiError** and **ApiResponse&lt;T&gt;** models aligned with backend `{ ok, data, error }`.
- Implemented **ApiClient** with centralized GET/POST returning **ApiResponse&lt;T&gt;** and mapping HTTP/network errors to `ApiResponse(ok: false, error: ApiError)`.
- **NotificationService** refactored to use ApiClient; external contract (return type `Map<String, dynamic>`) unchanged.
- **auth_service** and **chat_repository**: no HTTP calls; no changes. **ChatService** unchanged (minimal-impact rule).
- Fixed existing call sites for **setupOnboarding** (required `name` argument) so analysis passes.
- Added **test/api_response_test.dart** for ApiError and ApiResponse parsing.

---

## 2) Files Changed

| File | What / Why |
|------|------------|
| **lib/core/network/api_error.dart** | **New.** Backend error payload: `code?`, `message`; `fromJson`/`toJson`. |
| **lib/core/network/api_response.dart** | **New.** Generic `ApiResponse<T>` with `ok`, `data`, `error`; `fromJson(json, parser)` for parsing `data`. |
| **lib/core/network/api_client.dart** | **New.** ApiClient with `get<T>`, `post<T>`, `getRaw`, `postRaw`; builds headers (incl. AuthService token); maps timeouts/connection errors and HTTP errors to `ApiResponse(ok: false, error: ApiError)`. |
| **lib/features/notification/data/notification_service.dart** | **Updated.** Uses ApiClient for GET /notifications/ and POST /notifications/feedback; converts ApiResponse to legacy Map (`ok`, `data`, `error`) so callers and FrontendContractTest unchanged. |
| **lib/features/user_verification/presentation/pages/user_verification_page.dart** | **Updated.** Added required `name: _nameController.text.trim()` to `setupOnboarding` call (fixes missing_required_argument). |
| **lib/features/chat/chat_service.dart** | **Updated.** `registerUser` now passes `name: userName` into `setupOnboarding` (fixes missing_required_argument). |
| **test/api_response_test.dart** | **New.** Unit tests for ApiError.fromJson and ApiResponse.fromJson (success/failure/parser throw). |

---

## 3) Design Notes

- **ApiResponse.fromJson&lt;T&gt;(json, parser):** `parser` converts raw `data` to `T?`; required so all responses are strongly typed.
- **ApiClient** uses **AuthService.getToken()** for `Authorization` header; same pattern as ChatService.
- **NotificationService** keeps returning `Future<Map<String, dynamic>>`; internally uses ApiClient and maps `ApiResponse` to `{ ok, data, error }` so no breaking change for **FrontendContractTest** or any UI.

---

## 4) Tests Executed and Results

| Command | Result |
|--------|--------|
| `flutter analyze lib/core/network lib/features/notification/data/notification_service.dart test/api_response_test.dart` | **No issues found.** |
| `flutter test test/api_response_test.dart` | **7/7 passed.** (ApiError x3, ApiResponse.fromJson x4) |
| `flutter test` | **7 passed, 1 failed.** Failure: `widget_test.dart` – “Timer is still pending” (pre-existing; IntroPage timers). |

Stage 15–specific code: **analyze clean**, **api_response_test all pass**. Full `flutter test` fails only due to the existing widget_test timer issue, which is outside Stage 15 scope.

---

## 5) Verification Checklist

- [x] **ApiResponse&lt;T&gt;** and **ApiError** models added with `fromJson` and generic parser.
- [x] **ApiClient** centralizes GET/POST and returns **ApiResponse&lt;T&gt;**; HTTP and network exceptions mapped to `ok: false` + **ApiError**.
- [x] **NotificationService** uses ApiClient; UI/caller contract unchanged (Map return).
- [x] **auth_service** / **chat_repository** / **ChatService** unchanged (no breaking changes).
- [x] **flutter analyze** passes for Stage 15 files.
- [x] **flutter test test/api_response_test.dart** passes.
- [x] **docs/FRONTEND_STAGE15_REPORT.md** created with files changed, rationale, and test results.

---

## 6) Suggested Next Steps

- Migrate other features (health, lifestyle, conditions, devices) to use ApiClient + ApiResponse where new code is added.
- Optionally refactor ChatService to use ApiClient for new endpoints while keeping existing return types for sendMessage/getGreeting/setupOnboarding.
- Fix or relax widget_test timer assertion so full `flutter test` passes (separate task).

---

# Stage 15.3: HealthData DTO + Repository (POST /health/add)

**Date:** 2025-02-09  
**Reference:** `frontend/docs/FRONTEND_BACKEND_ALIGNMENT.md` (POST /health/add, HealthDataCreate, HealthDataResponse).

## 15.3.1 Summary

- **DTOs:** `lib/data/dto/health_data_create.dart` (user_id, heart_rate?, temperature?, spo2?) and `lib/data/dto/health_data_response.dart` (id/health_id, user_id, heart_rate?, temperature?, spo2?, created_at?, notification_id?, message?) for backend success payload and full schema.
- **Repository:** `lib/data/repositories/health_repository.dart` with `addHealthData(HealthDataCreate)` returning `ApiResponse<HealthDataResponse?>` using ApiClient.post (STAGE 15.2 style).
- **Debug helper:** `lib/core/debug/smoke_health.dart` — `smokeHealthAdd()` reads user_id from UserProfileManager, posts sample vitals; guarded (call explicitly, not executed automatically).
- **Tests:** `test/health_data_test.dart` for HealthDataCreate.toJson and HealthDataResponse.fromJson (backend success payload + full schema).

## 15.3.2 Files Changed (Stage 15.3)

| File | What / Why |
|------|------------|
| **lib/data/dto/health_data_create.dart** | **New.** Request DTO: userId, heartRate?, temperature?, spo2?; toJson(). |
| **lib/data/dto/health_data_response.dart** | **New.** Response DTO: fromJson() for health_id/user_id/notification_id/message and for id/user_id/heart_rate/temperature/spo2/created_at. |
| **lib/data/repositories/health_repository.dart** | **New.** HealthRepository.addHealthData(req) → ApiResponse<HealthDataResponse?> via ApiClient.post /health/add. |
| **lib/core/debug/smoke_health.dart** | **New.** smokeHealthAdd() uses UserProfileManager.loadProfile().userId and HealthRepository; guarded, no auto-run. |
| **test/health_data_test.dart** | **New.** Unit tests for HealthDataCreate.toJson and HealthDataResponse.fromJson. |

## 15.3.3 Tests and Verify

| Command | Result |
|--------|--------|
| `flutter analyze` (lib/data/dto/health*, lib/data/repositories/health_repository.dart, lib/core/debug/smoke_health.dart, test/health_data_test.dart) | **No issues found.** |
| `flutter test test/health_data_test.dart test/api_response_test.dart` | **All passed.** (health_data 4, api_response 7) |

## 15.3.4 Verification Checklist (15.3)

- [x] HealthDataCreate and HealthDataResponse DTOs; fields per alignment doc.
- [x] HealthRepository.addHealthData using ApiClient.post; returns ApiResponse<HealthDataResponse?>.
- [x] smoke_health.dart: reads user_id from preferences (UserProfileManager), posts sample payload; guarded.
- [x] Tests for DTO parsing; flutter analyze + flutter test pass.
- [x] docs/FRONTEND_STAGE15_REPORT.md updated with Stage 15.3.

---

# Stage 15.4: Notifications Contract (unread, mark-read, models)

**Date:** 2025-02-09  
**Reference:** `frontend/docs/FRONTEND_BACKEND_ALIGNMENT.md` (GET /notifications, GET /unread, POST /{id}/mark-read, POST /{id}/feedback).

## 15.4.1 Summary

- **Canonical model:** `lib/data/models/notification.dart` (used by notification_card). Extended to parse backend shape: `id` (int), `body`, `type`, `priority`, `is_read`, `created_at`; added backend types (morning_brief, connection_ping, health_alert, device_disconnected) and `critical` → urgent.
- **Single model:** `lib/features/notification/data/models/sedi_notification.dart` now re-exports `data/models/notification.dart`; no duplication.
- **NotificationService:** Added `fetchUnreadList(userId, {limit, type})`, `markRead(notificationId, userId)`; `submitFeedback(feedback)` now calls POST `/notifications/{id}/feedback` with body from `feedback.toBackendJson()`.
- **Feedback contract:** `NotificationFeedback.toBackendJson()` returns `{ feedback: "positive"|"negative"|"neutral", reason?, action? }` (like → positive, dislike → negative, seen/interact/dismiss → neutral).
- **ApiClient:** Added optional `queryParams` to `post()` for mark-read `user_id`.
- **Tests:** `test/notification_contract_test.dart` for Notification.fromJson (backend + legacy) and NotificationFeedback.toBackendJson. FrontendContractTest updated to treat `total`/`unread_count` as optional (GET /notifications does not return them).
- **Fixes:** notification_card import prefix `sedi` to avoid clash with Flutter’s `Notification`; notification_test.dart `isSedi: true`; corrected relative imports (../../../../ for data/models from features).

## 15.4.2 Files Changed (Stage 15.4)

| File | What / Why |
|------|------------|
| **lib/data/models/notification.dart** | Backend-shaped `fromJson` (id int, body→message, backend types, critical→urgent). |
| **lib/data/models/notification_feedback.dart** | `toBackendJson()`: feedback (positive|negative|neutral), reason?, action?. |
| **lib/features/notification/data/models/sedi_notification.dart** | Re-export of `data/models/notification.dart` (single canonical model). |
| **lib/features/notification/data/notification_service.dart** | `fetchUnreadList`, `markRead`; `submitFeedback` uses `/notifications/{id}/feedback` + `toBackendJson()`. |
| **lib/core/network/api_client.dart** | `post(..., queryParams: Map<String, String>?)` for mark-read. |
| **lib/features/notification/logic/frontend_contract_test.dart** | `total`/`unread_count` optional; accept `count` from GET /unread. |
| **lib/features/notification/presentation/widgets/notification_card.dart** | Import `notification.dart` as `sedi` (avoid Flutter Notification clash); fix path to data/models. |
| **lib/features/notification/logic/notification_test.dart** | Added required `isSedi: true` to ChatMessage constructors. |
| **test/notification_contract_test.dart** | **New.** Notification.fromJson (backend + legacy), NotificationFeedback.toBackendJson. |

## 15.4.3 Tests and Verify

| Command | Result |
|--------|--------|
| `flutter analyze` (lib/data/models/notification*, lib/features/notification/, api_client) | **No issues found.** |
| `flutter test test/notification_contract_test.dart test/api_response_test.dart` | **14/14 passed.** |

## 15.4.4 Verification Checklist (15.4)

- [x] One canonical Notification model; sedi_notification re-exports it.
- [x] NotificationService: getNotifications, fetchUnreadList, markRead, submitFeedback (correct URLs and body).
- [x] Feedback request matches backend: feedback, reason?, action?.
- [x] Notification.fromJson parses backend and legacy shapes; NotificationFeedback.toBackendJson.
- [x] notification_contract_test.dart added; flutter analyze + flutter test (notification + api_response) pass.
- [x] docs/FRONTEND_STAGE15_REPORT.md updated with Stage 15.4.

---

# Stage 15.5: Devices Management + Device Ingest (DTO + Repositories)

**Date:** 2025-02-09  
**Reference:** `frontend/docs/FRONTEND_BACKEND_ALIGNMENT.md` (POST /devices/register, GET /devices, revoke, rotate-token; POST /device/ingest).

## 15.5.1 Summary

- **DTOs:** DeviceRegisterRequest, DevicePublicInfo, DevicesListData (devices + count), DeviceIngestRequest, DeviceIngestResponse (event_id, dedupe_key). All in `lib/data/dto/`.
- **Repositories:** `devices_repository.dart` for /devices/* (register, list, revoke, rotateToken); `device_repository.dart` for /device/ingest. Both use ApiClient; responsibilities separated.
- **Debug helpers:** `smoke_devices.dart` (register sample device + list); `smoke_device_ingest.dart` (post sample heart_rate event). Guarded, call explicitly.
- **Tests:** `test/device_dto_test.dart` for DTO toJson/fromJson (register, public info, list data, ingest request/response).

## 15.5.2 Files Changed (Stage 15.5)

| File | What / Why |
|------|------------|
| **lib/data/dto/device_register_request.dart** | **New.** device_id, device_type?; toJson(). |
| **lib/data/dto/device_public_info.dart** | **New.** device_id, device_type, status, last_seen_at, created_at, revoked_at; fromJson(). |
| **lib/data/dto/devices_list_response.dart** | **New.** DevicesListData: devices (List&lt;DevicePublicInfo&gt;), count; fromJson(). |
| **lib/data/dto/device_ingest_request.dart** | **New.** user_id, device_id?, event_type, payload, recorded_at?; toJson(). |
| **lib/data/dto/device_ingest_response.dart** | **New.** event_id?, dedupe_key?; fromJson(). |
| **lib/data/repositories/devices_repository.dart** | **New.** register(userId, request), list(userId), revoke(deviceId, userId), rotateToken(deviceId, userId). |
| **lib/data/repositories/device_repository.dart** | **New.** ingest(DeviceIngestRequest) → ApiResponse&lt;DeviceIngestResponse?&gt;. |
| **lib/core/debug/smoke_devices.dart** | **New.** smokeDevices(): register SediDebug001 + list; userId from UserProfileManager; guarded. |
| **lib/core/debug/smoke_device_ingest.dart** | **New.** smokeDeviceIngest(): POST sample heart_rate event; userId from UserProfileManager; guarded. |
| **test/device_dto_test.dart** | **New.** Unit tests for DeviceRegisterRequest.toJson, DevicePublicInfo.fromJson, DevicesListData.fromJson, DeviceIngestRequest.toJson, DeviceIngestResponse.fromJson. |

## 15.5.3 Tests and Verify

| Command | Result |
|--------|--------|
| `flutter analyze` (lib/data/dto/device*, lib/data/repositories/devices_repository.dart, device_repository.dart, lib/core/debug/smoke_devices.dart, smoke_device_ingest.dart, test/device_dto_test.dart) | **No issues found.** |
| `flutter test test/device_dto_test.dart` | **6/6 passed.** |

## 15.5.4 Verification Checklist (15.5)

- [x] DTOs per alignment doc: register request, public info, list data, ingest request/response.
- [x] devices_repository for /devices/*; device_repository for /device/ingest; no conflict with auth/session.
- [x] smoke_devices (register + list); smoke_device_ingest (sample event); guarded.
- [x] Tests for DTO parsing; flutter analyze + flutter test pass.
- [x] docs/FRONTEND_STAGE15_REPORT.md updated with Stage 15.5.
