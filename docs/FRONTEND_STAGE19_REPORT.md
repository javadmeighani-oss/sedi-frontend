# Stage 19.1 Report: Lifestyle DTO + Repository (update/context)

**Date:** 2025-02-10  
**Reference:** FRONTEND_BACKEND_ALIGNMENT.md (LifestyleDataCreate, POST /lifestyle/update, GET /lifestyle/context); ApiClient + ApiResponse (Stage 15.2).

---

## 1) Summary

- **DTOs:** `LifestyleDataCreate` (user_id, sleep_hours?, steps?, calories?, stress_level?) for POST /lifestyle/update; `LifestyleContextResponse` for parsing GET /lifestyle/context data (flexible: object or null).
- **Repository:** `LifestyleRepository` — `fetchContext(int userId)`, `updateLifestyle(LifestyleDataCreate req)`; both return `ApiResponse<Map<String, dynamic>?>`; uses ApiClient get/post.
- **Debug (optional):** `smokeLifestyleUpdate()`, `smokeLifestyleContext()` in lib/core/debug/smoke_lifestyle.dart; guarded, not auto-run.
- **Tests:** `lifestyle_dto_test.dart` — LifestyleDataCreate.toJson, LifestyleContextResponse.fromJson / fromApiData.

---

## 2) Files Changed / Added

| File | What |
|------|------|
| **lib/data/dto/lifestyle_data_create.dart** | **New.** Request DTO: user_id, sleep_hours?, steps?, calories?, stress_level?; toJson(). |
| **lib/data/dto/lifestyle_context_response.dart** | **New.** Response parsing: fromJson(Map?), fromApiData(Object?); fields sleep_hours, steps, calories, stress_level, raw. |
| **lib/data/repositories/lifestyle_repository.dart** | **New.** fetchContext(userId) GET /lifestyle/context; updateLifestyle(req) POST /lifestyle/update; ApiResponse<Map<String, dynamic>?>. |
| **lib/core/debug/smoke_lifestyle.dart** | **New.** smokeLifestyleUpdate(), smokeLifestyleContext(); UserProfileManager for userId. |
| **test/lifestyle_dto_test.dart** | **New.** LifestyleDataCreate toJson; LifestyleContextResponse fromJson, fromApiData. |
| **docs/FRONTEND_STAGE19_REPORT.md** | **New.** This report. |

---

## 3) Verify

| Command | Purpose |
|--------|---------|
| `flutter analyze` | Check lib/data/dto, lib/data/repositories, lib/core/debug (lifestyle). |
| `flutter test test/lifestyle_dto_test.dart test/api_response_test.dart` | Lifestyle DTOs + API response. |

---

# Stage 19.2 Report: Lifestyle UI (Apple-like) — manual update + context + RTL

**Date:** 2025-02-10  
**Reference:** Stage 19.1 repository + DTOs; AppTheme; Language/RTL from Vitals/Devices.

---

## 1) Summary (Stage 19.2)

- **Controller:** `LifestyleController` — `loadContext()`, `submitUpdate(sleepHours, steps, calories, stressLevel)`; state: `isLoading`, `isSubmitting`, `contextMap`, `errorMessage`; uses LifestyleRepository + UserProfileManager.
- **UI:** `LifestylePage` — (1) Context section: show key fields from context if available, else placeholder "No lifestyle context yet."; (2) Update form: Sleep hours (0–24), Steps (0–100000), Calories (0–20000), Stress level (0–10); (3) Submit button with loading state; SnackBars (English) success/error; RTL for fa/ar; numeric inputs LTR.
- **Navigation:** Overflow menu (more_vert) in Chat header with "Lifestyle" entry; no extra icon to avoid clutter.
- **Validation:** Pure functions in `lifestyle_validation.dart` (sleep 0–24, steps 0–100000, calories 0–20000, stress 0–10); tested in `lifestyle_validation_test.dart`.

---

## 2) Files Changed (Stage 19.2)

| File | What |
|------|------|
| **lib/features/lifestyle/logic/lifestyle_validation.dart** | **New.** validateSleepHours, validateSteps, validateCalories, validateStressLevel (pure). |
| **lib/features/lifestyle/logic/lifestyle_controller.dart** | **New.** loadContext(), submitUpdate(); state isLoading, isSubmitting, contextMap, errorMessage; parsedContext getter. |
| **lib/features/lifestyle/presentation/pages/lifestyle_page.dart** | **New.** Context section, Update form, submit, SnackBars, RTL. |
| **lib/features/chat/presentation/pages/chat_page.dart** | **Updated.** PopupMenuButton (more_vert) with Lifestyle → LifestylePage. |
| **test/lifestyle_validation_test.dart** | **New.** Range validations for sleep, steps, calories, stress. |
| **docs/FRONTEND_STAGE19_REPORT.md** | Stage 19.2 section (this). |

---

## 3) Verify (Stage 19.2)

| Command | Purpose |
|--------|---------|
| `flutter analyze` | Check lib/features/lifestyle, chat. |
| `flutter test test/lifestyle_dto_test.dart test/lifestyle_validation_test.dart` | DTOs + validation. |
