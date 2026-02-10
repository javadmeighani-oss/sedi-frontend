# Stage 18.1 Report: Devices UI (Apple-like) — List / Register / Status / Last seen

**Date:** 2025-02-10  
**Reference:** FRONTEND_BACKEND_ALIGNMENT.md (GET /devices, POST /devices/register); Stage 15.5 DTOs and DevicesRepository.

---

## 1) Summary

- **Devices screen:** New `DevicesPage` shows registered devices list and a register form (device_id required, device_type optional). Apple-like minimal UI: AppTheme colors, subtle borders, pull-to-refresh.
- **Controller:** `DevicesController` — `loadDevices()`, `registerDevice(deviceId, deviceType?)`; state: `isLoading`, `devices`, `errorMessage`. Uses existing `DevicesRepository` (no new network layer).
- **Device card:** device_id (monospace), device_type, status (Active/Revoked), last_seen_at (formatted or "Never"). Loading and error states handled.
- **Navigation:** Devices icon (Icons.devices) in Chat header opens `DevicesPage`; existing icons (notifications, vitals, history) unchanged.
- **RTL:** Language from `UserPreferences.getUserLanguage()`; fa/ar wrap with `Directionality.rtl`; IDs and values stay LTR.
- **Tests:** `devices_controller_mapping_test.dart` — UI mapping: `deviceStatusLabel` (Active/Revoked), `deviceLastSeenLabel` (Never / time / date).

---

## 2) Files Changed / Added

| File | What |
|------|------|
| **lib/features/devices/logic/devices_controller.dart** | **New.** loadDevices(), registerDevice(); state isLoading, devices, errorMessage; deviceStatusLabel(), deviceLastSeenLabel(). |
| **lib/features/devices/presentation/pages/devices_page.dart** | **New.** Register form (device_id, device_type), pull-to-refresh list, device cards (id mono, type, status, last seen), RTL. |
| **lib/features/chat/presentation/pages/chat_page.dart** | **Updated.** Devices icon opens DevicesPage. |
| **test/devices_controller_mapping_test.dart** | **New.** deviceStatusLabel, deviceLastSeenLabel mapping tests. |
| **docs/FRONTEND_STAGE18_REPORT.md** | **New.** This report. |

---

## 3) Verify

| Command | Purpose |
|--------|---------|
| `flutter analyze` | Check lib/features/devices and chat. |
| `flutter test test/device_dto_test.dart test/devices_controller_mapping_test.dart` | DTO parsing + controller mapping. |

---

## 4) TODO (Stage 18.2+)

- [x] **Revoke / Rotate:** Long-press on device card → Revoke, Rotate token (Stage 18.2 done).
- [ ] **Ingest status:** Show device ingest/heartbeat status on card if backend exposes it.

---

# Stage 18.2 Report: Devices Actions — Revoke / Rotate + UI polish + safe refresh

**Date:** 2025-02-10  
**Reference:** FRONTEND_STAGE18_REPORT.md (18.1), FRONTEND_BACKEND_ALIGNMENT.md (POST revoke, rotate-token), devices_repository.dart.

---

## 1) Summary (Stage 18.2)

- **Controller:** `revokeDevice(deviceId)` and `rotateDeviceToken(deviceId)`; each gets userId, calls repo, on success calls `loadDevices()`, returns true/false and sets `errorMessage` on failure. `isActionInProgress` + try/finally prevent concurrent actions. Controller accepts optional `DevicesRepository? repo` and `int? testUserId` for testability.
- **UI:** Long-press on device card opens a bottom sheet: Revoke, Rotate token, Copy device ID. Revoke and Rotate show confirmation dialogs ("Revoke this device?" / "Rotate device token?"). Success → SnackBar; list refresh via controller. Failure → SnackBar with `errorMessage`. Trailing three-dots (more_vert) on card; neutral colors; subtle red only for "Revoked" label.
- **Tests:** `devices_controller_actions_test.dart` — `FakeDevicesRepository` stub; revokeDevice and rotateDeviceToken trigger loadDevices on success. Existing device_dto_test and devices_controller_mapping_test unchanged.

---

## 2) Files Changed (Stage 18.2)

| File | What |
|------|------|
| **lib/features/devices/logic/devices_controller.dart** | Injectable `repo` and `testUserId`; `_getUserId()`; `isActionInProgress`; `revokeDevice()`, `rotateDeviceToken()` with try/finally; guard on register/revoke/rotate when action in progress. |
| **lib/features/devices/presentation/pages/devices_page.dart** | Long-press → modal bottom sheet (Revoke, Rotate token, Copy device ID); confirm dialogs; SnackBar success/failure; trailing more_vert on card; register button disabled when `isActionInProgress`. |
| **test/devices_controller_actions_test.dart** | **New.** FakeDevicesRepository; tests that revoke/rotate call repo and trigger list (loadDevices). |
| **docs/FRONTEND_STAGE18_REPORT.md** | Stage 18.2 section (this). |

---

## 3) Verify (Stage 18.2)

| Command | Purpose |
|--------|---------|
| `flutter analyze` | Check lib/features/devices. |
| `flutter test test/device_dto_test.dart test/devices_controller_mapping_test.dart test/devices_controller_actions_test.dart` | DTO + mapping + actions. |

---

## 4) Known limitations

- Revoke/rotate do not show inline loading on the card; register button is disabled during any action via `isActionInProgress`.
- Copy device ID copies to clipboard; no visual feedback beyond SnackBar.
