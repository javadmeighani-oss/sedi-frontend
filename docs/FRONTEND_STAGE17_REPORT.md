# Stage 17.1 Report: Vitals UI (Apple-like) + Manual Add + Local Cache + RTL

**Date:** 2025-02-09  
**Reference:** FRONTEND_BACKEND_ALIGNMENT.md (POST /health/add, HealthDataCreate/Response); Stage 15.3 DTOs and HealthRepository.

---

## 1) Summary

- **Vitals screen:** New `VitalsPage` shows last known vitals from local cache and a manual-add form (Heart rate required; SpO2 and Temperature optional). Apple-like minimal UI: neutral surfaces, subtle dividers, AppTheme colors.
- **Local cache:** SharedPreferences key `last_vitals_<userId>`. JSON shape: `heart_rate`, `temperature`, `spo2`, `created_at`. Loaded when page opens; updated on successful submit (from response or submitted values + current timestamp).
- **Manual add:** Validation ranges — HR 30–220, SpO2 50–100, Temp 30–45. Submit calls `HealthRepository.addHealthData(HealthDataCreate)`; on success cache is updated and SnackBar shown; on error SnackBar with message. Submit button shows loading state.
- **Navigation:** Chat header heart icon (favorite_border) opens `VitalsPage`. Notifications and other icons unchanged.
- **RTL:** Language from `UserPreferences.getUserLanguage()`; if `fa` or `ar`, page wrapped with `Directionality.rtl`. Value text uses `textDirection: TextDirection.ltr` for numbers.
- **Tests:** `vitals_cache_test.dart` for `CachedVitals` serialize/deserialize and validation helpers (`validateHeartRate`, `validateSpO2`, `validateTemperature`).

---

## 2) Files Changed / Added

| File | What |
|------|------|
| **lib/features/health/logic/vitals_cache.dart** | **New.** `CachedVitals` model (toJson/fromJson), `loadLastVitals(userId)`, `saveLastVitals(userId, vitals)`, `validateHeartRate`, `validateSpO2`, `validateTemperature`. |
| **lib/features/health/logic/vitals_controller.dart** | **New.** Minimal controller: `loadCachedVitals()`, `submit(heartRate, spo2?, temperature?)` — uses HealthRepository, updates cache on success. |
| **lib/features/health/presentation/widgets/vital_value_tile.dart** | **New.** Apple-like row: label + value (+ optional unit). LTR for value. |
| **lib/features/health/presentation/pages/vitals_page.dart** | **New.** Last-recorded section (from cache), form (HR required, SpO2/Temp optional), submit with loading, SnackBar; RTL wrap for fa/ar. |
| **lib/features/chat/presentation/pages/chat_page.dart** | **Updated.** Heart icon opens `VitalsPage`. |
| **test/vitals_cache_test.dart** | **New.** CachedVitals serialization/deserialize, validation logic. |
| **docs/FRONTEND_STAGE17_REPORT.md** | **New.** This report. |

---

## 3) Design Notes

- **Cache key:** `last_vitals_<userId>` so each user has their own last vitals.
- **Backend contract:** Unchanged. `HealthDataCreate` uses `userId`, `heart_rate`, `temperature`, `spo2` (doubles). Form sends HR/SpO2 as int then converted to double for DTO.
- **Success cache:** If response `data` contains vitals fields, cache those + `createdAt` (or current time); otherwise cache submitted values + `DateTime.now()`.
- **Single responsibility:** Cache and validation in `vitals_cache.dart`; controller in `vitals_controller.dart`; UI in page and tile.

---

## 4) Tests and Verify

| Command | Purpose |
|--------|---------|
| `flutter pub get` | Resolve dependencies. |
| `flutter analyze` | Check lib/features/health, lib/features/chat (vitals nav). |
| `flutter test test/vitals_cache_test.dart test/health_data_test.dart test/api_response_test.dart` | Stage 17 + Stage 15 + API response. |
| `flutter test` | Full test suite (optional). |

---

## 5) Verification Checklist

- [x] VitalsPage + VitalValueTile + VitalsController.
- [x] Local cache: SharedPreferences `last_vitals_<userId>`, load on open, update on submit success.
- [x] Manual form: HR required (30–220), SpO2/Temp optional with ranges; submit loading state; SnackBar success/error.
- [x] HealthRepository.addHealthData used; cache updated from response or submitted values.
- [x] Navigation from Chat header (heart icon) to VitalsPage.
- [x] RTL via UserPreferences.getUserLanguage(); numbers LTR.
- [x] vitals_cache_test: serialization and validation.
- [x] docs/FRONTEND_STAGE17_REPORT.md.

---

# Stage 17.2 Report: Fetch Latest from Server + Cache Sync

**Date:** 2025-02-09  
**Reference:** FRONTEND_BACKEND_ALIGNMENT.md (health); Stage 17.1 vitals page and cache.

---

## 1) Summary (Stage 17.2)

- **Fetch latest:** On load, vitals page (1) loads from local cache, (2) tries to fetch latest from backend. Endpoints tried in order until one succeeds: `GET /health/latest?user_id=<id>`, then `GET /health/context?user_id=<id>`, then `GET /health?user_id=<id>`. First successful response is used; if all fail (404/405/network), we keep cache and do not show an error.
- **Parsing:** Backend `data` may be a single object or a list. `HealthDataResponse.fromApiData(data)` handles both; for a list, the newest by `created_at` is chosen, otherwise the first item.
- **Controller state:** `VitalsController` exposes `isLoading`, `lastVitals`, `lastSource` (`'server'` or `'cache'`). `load()` loads cache first, then attempts fetch; on success it updates cache and sets `lastSource = server`.
- **UI:** Subtle label next to "Last recorded": "Source: Server" or "Source: Local" (English), with `textDirection: TextDirection.ltr` so it stays readable in RTL.
- **Tests:** `health_latest_parse_test.dart` — parse when data is object, when data is list, pick newest by `created_at`; null and empty list. ApiClient already supported `queryParams` for GET; no new URL test added.

---

## 2) Endpoints Attempted (Stage 17.2)

| Order | Endpoint | Query |
|-------|----------|--------|
| 1 | GET `/health/latest` | `user_id=<userId>` |
| 2 | GET `/health/context` | `user_id=<userId>` |
| 3 | GET `/health` | `user_id=<userId>` |

Stop at first success (ok and data != null). If all fail, last vitals remain from cache; no SnackBar or error to the user.

---

## 3) Fallback Behavior

- Load cache first → show "Source: Local" and cached vitals.
- Then call fetch (try the three endpoints in order).
- If any returns success with data: update cache, set lastVitals from response, set "Source: Server".
- If all fail: leave lastVitals and lastSource unchanged (user continues to see cached data). No error message.

---

## 4) Files Changed (Stage 17.2)

| File | What |
|------|------|
| **lib/data/dto/health_data_response.dart** | `fromApiData(Object? data)` — accept object or list; if list, pick newest by `created_at` else first. |
| **lib/data/repositories/health_repository.dart** | `fetchLatestHealthData(userId)` — try the three GET endpoints in order; use `fromApiData` for parsing. |
| **lib/features/health/logic/vitals_controller.dart** | `load()`, `isLoading`, `lastVitals`, `lastSource`; load cache then fetch; on success update cache and set source = server. |
| **lib/features/health/presentation/pages/vitals_page.dart** | Use `_controller.load()` and `lastVitals`/`lastSource`; show "Source: Server" / "Source: Local" with LTR. |
| **test/health_latest_parse_test.dart** | **New.** Parse object, list (first), list (newest by created_at), null, empty list. |

---

## 5) Tests and Verify (Stage 17.2)

| Command | Purpose |
|--------|---------|
| `flutter analyze` | Check health, repository, DTO. |
| `flutter test test/vitals_cache_test.dart test/health_data_test.dart test/api_response_test.dart test/health_latest_parse_test.dart` | Stage 17.1 + Stage 15 + API response + latest parse. |

---

# Stage 17.3 Report: Vitals Mini-Trend (7-day) — Local Rolling History

**Date:** 2025-02-10  
**Reference:** Stage 17.1/17.2 (vitals_cache, vitals_controller, vitals_page). No chart libraries; Apple-like minimal UI.

---

## 1) Summary (Stage 17.3)

- **Rolling history:** Per-user key `vitals_history_<userId>` in SharedPreferences. JSON list of `CachedVitals` entries (heart_rate, spo2, temperature, created_at). On every successful submit and when server latest is loaded, append/merge: newest first, deduplicate by created_at+heart_rate (or created_at alone if present), cap at 50 items and purge entries older than 7 days.
- **Derived stats:** `avgHeartRate7d` (int, rounded), optional min/max heart rate in window, `countRecords7d`. Placeholders (e.g. "—") when no data.
- **Controller:** After updating `lastVitals`, history is updated; exposes read-only `recentHistory`, `avgHeartRate7d`, `countRecords7d`.
- **UI:** "Trend" section under "Last recorded": row "7-day average HR" with value; small list of last 5 entries (time + HR) as chips. Numbers LTR in RTL layout.
- **Tests:** `vitals_history_test.dart` — append + cap to 50, purge older than 7 days, dedup logic, avg computation rounding. Existing tests unchanged.

---

## 2) Storage and Windowing (Stage 17.3)

| Item | Detail |
|------|--------|
| **Storage key** | `vitals_history_<userId>` |
| **Value** | JSON array of objects: `heart_rate`, `temperature`, `spo2`, `created_at` (same shape as `CachedVitals.toJson()`). |
| **Merge** | New entry merged into existing list; sort newest first. |
| **Dedup** | By `created_at` + `heart_rate` when both present; by `created_at` only otherwise. |
| **Cap** | At most 50 items. |
| **Purge** | Remove entries older than 7 days (on write and on read). |

---

## 3) Files Changed / Added (Stage 17.3)

| File | What |
|------|------|
| **lib/features/health/logic/vitals_history.dart** | **New.** Rolling history: `appendVitalsHistoryEntry`, `loadVitalsHistory`, `mergeAndTrim`, `purgeOlderThan7Days`, `computeStats`, `VitalsHistoryStats`, `VitalsHistory` namespace. |
| **lib/features/health/logic/vitals_controller.dart** | After `load()` and on submit success: update history; expose `recentHistory`, `avgHeartRate7d`, `countRecords7d`; internal `_refreshHistory(userId)`. |
| **lib/features/health/presentation/pages/vitals_page.dart** | "Trend" section: 7-day average HR row; last 5 entries as time+HR chips; numbers LTR. |
| **test/vitals_history_test.dart** | **New.** mergeAndTrim cap 50, dedup (by created_at+hr and created_at only), purgeOlderThan7Days, computeStats rounding and empty/no-HR cases. |
| **docs/FRONTEND_STAGE17_REPORT.md** | Stage 17.3 section (this). |

---

## 4) UI Notes (Stage 17.3)

- Trend section sits under "Last recorded", above "Add vitals".
- "7-day average HR" shows value in bpm or "—" when no data.
- Last 5 history entries shown as small chips: time (LTR) + HR (LTR).
- EN default; FA/AR RTL layout; values remain LTR. No chart libraries; minimal Apple-like styling (neutral colors, subtle dividers).

---

## 5) Tests and Verify (Stage 17.3)

| Command | Purpose |
|--------|---------|
| `flutter analyze` | Check lib/features/health and test. |
| `flutter test test/vitals_cache_test.dart test/health_latest_parse_test.dart test/vitals_history_test.dart` | Stage 17 cache, latest parse, history (windowing, dedup, stats). |

---

## 6) Verification Checklist (Stage 17.3)

- [x] Rolling history key `vitals_history_<userId>`; append/merge on submit and when server latest loaded.
- [x] Windowing: newest first, dedup by created_at+heart_rate (or created_at), cap 50, purge &gt;7 days.
- [x] Derived stats: avgHeartRate7d (rounded), countRecords7d; placeholders when no data.
- [x] VitalsController: update history after lastVitals; expose recentHistory, avgHeartRate7d, countRecords7d.
- [x] VitalsPage: Trend section with 7-day average HR and last 5 entries (time + HR chips); numbers LTR.
- [x] vitals_history_test: append+cap 50, purge 7d, dedup, avg rounding.
- [x] No breaking changes to submit flow; existing tests unchanged.

---

# Stage 17.4 Report: Vitals UX/Resilience Polish

**Date:** 2025-02-10  
**Reference:** Stage 17.1–17.3. No new endpoints; no new dependencies.

---

## 1) Summary (Stage 17.4)

- **Input UX:** Numeric keyboards (HR, SpO2: `TextInputType.number`; Temp: `numberWithOptions(decimal: true)`). Input formatters: digits only for HR/SpO2; digits + one dot for temperature. Inline validation under fields: "Required" / "Out of range" (short English). Submit button disabled when invalid or loading.
- **Submit resilience:** `VitalsController.submit`: guard when `isLoading` or `isSubmitting` (return "Please wait."); `isSubmitting` set in try/finally. `load()` uses try/finally so `isLoading` is always cleared. Network errors mapped to friendly message: "Connection issue. Try again."
- **History consistency:** Dedup key uses `created_at` truncated to minute when available (avoids duplicate on every open); fallback "nodate" when no timestamp. Test: repeated append of same entry does not increase list; minute-bucket dedup (open page twice).
- **Tests:** `vitals_history_stability_test.dart` — repeated append of same entry does not increase list. `vitals_history_test.dart` — minute-bucket dedup test added.

---

## 2) Files Changed (Stage 17.4)

| File | What |
|------|------|
| **lib/features/health/presentation/pages/vitals_page.dart** | Temperature formatter (digits + one dot); inline validation (_hrError, _spo2Error, _tempError → "Required" / "Out of range"); _canSubmit; submit disabled when invalid or loading; try/finally around submit. |
| **lib/features/health/logic/vitals_controller.dart** | `isSubmitting`; guard `isLoading`/`isSubmitting` in submit; try/finally in submit and load; _isNetworkError → "Connection issue. Try again." |
| **lib/features/health/logic/vitals_history.dart** | Dedup key: created_at truncated to minute when available, else "nodate". |
| **test/vitals_history_test.dart** | Minute-bucket dedup test (same minute, different seconds). |
| **test/vitals_history_stability_test.dart** | **New.** Repeated append of same entry does not increase list. |
| **docs/FRONTEND_STAGE17_REPORT.md** | Stage 17.4 section (this). |

---

## 3) Verify (Stage 17.4)

| Command | Purpose |
|--------|---------|
| `flutter analyze` | Check lib/features/health and tests. |
| `flutter test test/vitals_history_test.dart test/vitals_history_stability_test.dart` | History + stability. |
