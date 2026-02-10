# Stage 16.2 Report: Apple-like Notifications UI + Like/Dislike Feedback + Local Notifications

**Date:** 2025-02-09  
**Reference:** FRONTEND_BACKEND_ALIGNMENT.md (notifications endpoints + feedback); existing notification feature.

---

## 1) Summary

- **Notifications Inbox page:** New `notifications_inbox_page.dart` with pull-to-refresh, list of cards (title, body, time, unread dot, Like/Dislike). On tap: `NotificationService.markRead`. RTL for FA/AR via `Directionality.rtl` and `UserPreferences.getUserLanguage()`.
- **NotificationCard redesigned:** Apple-like neutral UI (AppTheme surfaces, subtle borders), `SelectedReaction` state, Like/Dislike callbacks sending feedback with action `tap_like` / `tap_dislike` (using existing `NotificationFeedback.toBackendJson()`).
- **Local notifications:** `flutter_local_notifications` added; `LocalNotificationsService` (init with permissions + Android channel with sound, `showNotification` with high importance, playSound true). Android `res/raw/` created with README for custom sound (sedi_alarm).
- **Notification sync:** `notification_sync.dart` fetches recent notifications for current user, detects new via SharedPreferences seen ids, shows local notification for new items. Triggered once after user verification success (`UserVerificationPage` after saveProfile, before pop).
- **Navigation:** Chat page app bar has Notifications icon opening `NotificationsInboxPage`.
- **Tests:** `notification_ui_mapping_test.dart` for default title by type and reaction action constants.

---

## 2) Files Changed

| File | What / Why |
|------|-------------|
| **pubspec.yaml** | Added `flutter_local_notifications: ^17.2.3`. |
| **lib/features/notification/utils/notification_ui_mapping.dart** | **New.** `defaultTitleForNotificationType(type)`, `actionTapLike`, `actionTapDislike`. |
| **lib/features/notification/presentation/widgets/notification_card.dart** | **Redesigned.** Apple-like (AppTheme, subtle border); `SelectedReaction`, `displayAsUnread?`, `onLike`/`onDislike`; Like/Dislike send feedback with action tap_like/tap_dislike. |
| **lib/features/notification/presentation/pages/notifications_inbox_page.dart** | **New.** Inbox with pull-to-refresh, list of NotificationCard, markRead on tap, reaction state; RTL for FA/AR. |
| **lib/core/notifications/local_notifications_service.dart** | **New.** `init()` (permissions + Android channel with sound), `showNotification(id, title, body, payload)` with high importance, playSound. |
| **lib/features/notification/logic/notification_sync.dart** | **New.** `syncOnce()`: fetch notifications, detect new via SharedPreferences, show local notification for new. |
| **lib/features/user_verification/.../user_verification_page.dart** | **Updated.** After saveProfile success, call `NotificationSync.syncOnce()` then pop. |
| **lib/features/chat/.../chat_page.dart** | **Updated.** App bar: Notifications icon opens `NotificationsInboxPage`. |
| **android/app/src/main/res/raw/readme_sound.txt** | **New.** Instructions to add sedi_alarm.wav/mp3 for custom sound. |
| **test/notification_ui_mapping_test.dart** | **New.** Tests for default title by type and action constants. |

---

## 3) Design Notes

- **Reactions:** Like sends `NotificationFeedback.create(..., actionId: 'tap_like', reaction: FeedbackReaction.like)`; Dislike sends `actionId: 'tap_dislike'`, `reaction: FeedbackReaction.dislike`. Backend receives `feedback` (positive/negative) and `action` (tap_like/tap_dislike) via existing `toBackendJson()`.
- **RTL:** Inbox page loads language from `UserPreferences.getUserLanguage()`; if `fa` or `ar`, wraps body with `Directionality(textDirection: TextDirection.rtl, child: ...)`.
- **Local notifications:** Default system sound until user adds `res/raw/sedi_alarm.wav` (or .mp3). To use custom sound later: set `sound: RawResourceAndroidNotificationSound('sedi_alarm')` on channel/details.
- **Sync trigger:** Only after verification success to avoid breaking Intro/Onboarding/Verification flows.

---

## 4) Tests and Verify

| Command | Result / Note |
|--------|----------------|
| `flutter pub get` | **Required first.** If "authorization failed" to pub.dev, fix credentials (e.g. `dart pub token add https://pub.dev`) or network. |
| `flutter analyze` | After pub get: run on `lib/features/notification/`, `lib/core/notifications/`, `lib/features/chat/.../chat_page.dart`, `lib/features/user_verification/.../user_verification_page.dart`. |
| `flutter test test/notification_ui_mapping_test.dart` | Tests default title and action constants. |
| `flutter test test/notification_contract_test.dart` | Existing contract tests; keep passing. |
| Manual | Notifications Inbox opens from Chat app bar; pull-to-refresh; tap card marks read; Like/Dislike send feedback. After verification, sync runs and new notifications can show as local (with sound). |

---

## 5) Verification Checklist

- [x] Notifications Inbox page with pull-to-refresh, cards (title/body/time/unread dot, Like/Dislike).
- [x] NotificationCard Apple-like; selectedReaction; Like/Dislike call `submitFeedback` with tap_like/tap_dislike.
- [x] LocalNotificationsService: init (permissions + Android channel sound), showNotification (high priority, playSound).
- [x] notification_sync: fetch, detect new, show local; triggered after verification success.
- [x] RTL/language for FA/AR in Inbox.
- [x] Navigation from Chat to Inbox.
- [x] notification_ui_mapping_test added.
- [x] docs/FRONTEND_STAGE16_REPORT.md created.

---

## 6) TODO (for user / follow-up)

1. **Run `flutter pub get`** (and fix pub.dev auth if needed); then run `flutter analyze` and `flutter test`.
2. **Custom notification sound (optional):** Add `sedi_alarm.wav` or `sedi_alarm.mp3` under `android/app/src/main/res/raw/` and optionally set `sound: RawResourceAndroidNotificationSound('sedi_alarm')` in `LocalNotificationsService` (channel and/or details).
3. **iOS:** Add notification sound to `ios/Runner` and ensure included in Xcode build if targeting iOS.
4. **Fix widget_test timer** (if still failing) so full `flutter test` passes.

---

# Stage 16.3 Report: Notifications Delivery Hardening (Android/iOS sound, badge, sync)

**Date:** 2025-02-09  
**Reference:** FRONTEND_BACKEND_ALIGNMENT.md; Stage 16.2 files.

---

## 1) Summary (Stage 16.3)

- **Android custom sound:** `LocalNotificationsService` uses `RawResourceAndroidNotificationSound('sedi_alarm')` on channel and notification details. Channel id remains stable: `sedi_alerts`. File name: `sedi_alarm.wav` in `android/app/src/main/res/raw/` (see readme_sound.txt).
- **iOS sound:** Permission request includes sound, alert, badge. `DarwinNotificationDetails(sound: 'sedi_alarm.wav')`. Sound file must be added to `ios/Runner` and to Xcode **Copy Bundle Resources** (see iOS integration notes below).
- **Unread badge:** Chat header notifications icon shows a red badge with unread count (or "99+"). Count from `NotificationService.fetchUnreadList` / `parseUnreadCount`. Refreshed when opening Inbox (on return), after app resume, and on init.
- **Sync reliability:** `notification_sync.dart`: seen IDs stored in a rolling window (newest first, max 200); `lastSeenId` and `lastSeenTimestamp` stored in SharedPreferences; `syncOnce()` guarded against concurrent runs; sync on app resume via `WidgetsBindingObserver` on Chat page.
- **RTL:** Inbox already uses `UserPreferences.getUserLanguage()` and `Directionality`; badge label uses `textDirection: TextDirection.ltr` so numbers do not flip in RTL.
- **Tests:** `notification_sync_and_badge_test.dart` for `mergeSeenIdsRollingWindow` (rolling window) and `NotificationService.parseUnreadCount` (unread count mapping).

---

## 2) Files Changed (Stage 16.3)

| File | What / Why |
|------|-------------|
| **lib/core/notifications/local_notifications_service.dart** | Android: channel and details use `RawResourceAndroidNotificationSound('sedi_alarm')`. iOS: `DarwinNotificationDetails(sound: 'sedi_alarm.wav')`, init requests alert + sound + badge. |
| **android/app/src/main/res/raw/readme_sound.txt** | Exact file name `sedi_alarm.wav`, location, and rules (no extension in code reference). |
| **lib/features/notification/logic/notification_sync.dart** | Rolling window via `mergeSeenIdsRollingWindow` (newest first, max 200); store `lastSeenId` / `lastSeenTimestamp`; concurrency guard (`_syncing`); uses stable channel. |
| **lib/features/chat/presentation/pages/chat_page.dart** | `WidgetsBindingObserver`: on resume call `NotificationSync.syncOnce()` and `_refreshUnreadCount()`. Unread badge on notifications icon; refresh on open Inbox (return), init, resume. |
| **lib/features/notification/data/notification_service.dart** | `parseUnreadCount(resp)` for consistent unread count from fetchUnreadList response (used by Chat + tests). |
| **test/notification_sync_and_badge_test.dart** | **New.** Rolling window merge logic; `parseUnreadCount` mapping. |

---

## 3) Android sound setup

- **File:** `sedi_alarm.wav` (exact name).
- **Location:** `android/app/src/main/res/raw/sedi_alarm.wav`.
- **Code:** `RawResourceAndroidNotificationSound('sedi_alarm')` (name without extension). See `readme_sound.txt` in `android/app/src/main/res/raw/`.

---

## 4) iOS sound setup (integration notes)

- **Permission:** Init already requests alert, sound, and badge via `DarwinInitializationSettings(requestAlertPermission: true, requestSoundPermission: true, requestBadgePermission: true)`.
- **Sound file:** Use `sedi_alarm.wav` (or `.caf` if you convert; then set `sound: 'sedi_alarm.caf'` in code).
- **Where to place:** Put the sound file in the iOS app bundle, e.g.:
  - **Option A:** `ios/Runner/sedi_alarm.wav` (or inside `ios/Runner/` in a subfolder and add that folder to the bundle).
  - **Option B:** In Xcode, drag the file into the **Runner** target’s project navigator so it sits under `Runner`.
- **Xcode – Copy Bundle Resources:** In Xcode, select the **Runner** target → **Build Phases** → **Copy Bundle Resources**. Ensure `sedi_alarm.wav` (or your sound file) is listed. If not, click **+** and add it so the file is copied into the app bundle.
- **Code:** `LocalNotificationsService` uses `DarwinNotificationDetails(sound: 'sedi_alarm.wav')`. The string must match the file name (with extension) as present in the bundle.

---

## 5) Tests and Verify (Stage 16.3)

| Command | Result / Note |
|--------|----------------|
| `flutter pub get` | Run when network/pub access is available. |
| `flutter analyze` | Run on `lib/core/notifications/`, `lib/features/notification/`, `lib/features/chat/.../chat_page.dart`. |
| `flutter test test/notification_sync_and_badge_test.dart` | Rolling window and unread count parsing. |
| `flutter test test/notification_ui_mapping_test.dart` | Existing mapping tests. |
| Manual smoke | (1) Trigger a new notification from backend. (2) Ensure `syncOnce()` runs (e.g. on resume or after verification) and a local notification with sound appears. (3) Open Inbox, tap a card to mark read; return to Chat and confirm badge count decreases. |

---

## 6) Verification checklist (Stage 16.3)

- [x] Android: channel and details use `RawResourceAndroidNotificationSound('sedi_alarm')`; channel id `sedi_alerts` stable.
- [x] readme_sound.txt: exact file name and location.
- [x] iOS: permission request includes sound/alert/badge; `DarwinNotificationDetails(sound: 'sedi_alarm.wav')`; docs note placement and Copy Bundle Resources.
- [x] Unread badge on Chat notifications icon; refresh on open Inbox, resume, init.
- [x] Sync: rolling window (max 200), lastSeenId/lastSeenTimestamp, concurrency guard, sync on resume.
- [x] RTL: badge label `TextDirection.ltr`; Inbox uses UserPreferences + Directionality.
- [x] Tests: rolling window and parseUnreadCount.
