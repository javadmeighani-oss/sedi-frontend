# Stage 20.0 Report: UI Audit & Repair Pack

**Date:** 2025-02-10  
**Goal:** Review and polish existing UI for production-like field testing; Apple-like minimal look; EN default, FA/AR RTL correct.

---

## 1) Summary

- **Layout & consistency:** Chat header icon buttons use explicit `iconSize: 24` and `minimumSize: Size(44, 44)` for consistent tap targets. Overflow menu (more_vert) already used for Lifestyle to avoid header clutter. Horizontal padding 16 is used on Vitals, Devices, Lifestyle, Chat top bar; message list uses 16 left/right.
- **Chat UI:** Message list and input bar remain inside `SafeArea` (body is wrapped). Message bubbles use `AlignmentDirectional.centerStart` / `centerEnd` so RTL correctly places Sedi on start side and user on end side; no timestamps in bubbles (none were present).
- **Icons:** All header icons use `AppTheme.primaryBlack` (neutral); icon size 24. No separate “memory” icon found in the app; overflow menu icon (more_vert) follows same color/size.
- **Manual QA checklist:** Documented below.

---

## 2) Before / After Notes

| Area | Before | After |
|------|--------|--------|
| Chat header IconButtons | Default icon size (24), default tap target (~48). Color set per icon. | Explicit `iconSize: 24`, `IconButton.styleFrom(foregroundColor: AppTheme.primaryBlack, minimumSize: Size(44, 44))` for notifications, devices, favorite_border, history. |
| PopupMenuButton (overflow) | Icon with color. | Icon with explicit `size: 24` and `color: AppTheme.primaryBlack`. |
| MessageBubble alignment | `Alignment.centerLeft` / `centerRight` (fixed LTR). | `AlignmentDirectional.centerStart` / `centerEnd` so RTL flips bubble sides correctly. |
| Safe areas | Chat body already inside `SafeArea`; input bar `Positioned(bottom: keyboardHeight)` inside same. | No change; confirmed correct. |

---

## 3) Files Changed

| File | Change |
|------|--------|
| **lib/features/chat/presentation/pages/chat_page.dart** | IconButton: `iconSize: 24`, `style: IconButton.styleFrom(foregroundColor: AppTheme.primaryBlack, minimumSize: Size(44, 44))` for notifications, devices, favorite_border, history. PopupMenuButton icon: `Icon(Icons.more_vert, size: 24, color: AppTheme.primaryBlack)`. |
| **lib/features/chat/presentation/widgets/message_bubble.dart** | Alignment changed from `Alignment.centerLeft`/`centerRight` to `AlignmentDirectional.centerStart`/`centerEnd` for RTL-aware bubble alignment. |
| **docs/FRONTEND_STAGE20_REPORT.md** | This report. |

---

## 4) Icon Consistency

- **Style:** Outlined where available (e.g. `notifications_outlined`); fill for devices, favorite_border, history, more_vert.
- **Color:** All use `AppTheme.primaryBlack` (neutral). Accent (e.g. pistachio) not used in header to keep it minimal.
- **Size:** 24dp for all header and overflow icons.
- **Tap target:** Minimum 44×44 for IconButtons in header.
- **Memory icon:** Not present in codebase; no change.

---

## 5) Manual QA Checklist

Run through in order on a device or simulator:

1. **Intro** — Full-screen intro with logo; auto-navigation after ~2s.
2. **Onboarding** — If not completed: name, security password, flow to verification.
3. **Verification** — User verification step (if shown).
4. **Chat** — Main chat loads; header shows notifications, devices, heart (vitals), history, overflow (⋮). Tap each icon; overflow opens and “Lifestyle” navigates to Lifestyle. Send a message; Sedi reply aligns correctly. In RTL (fa/ar), bubbles align to start/end.
5. **Notifications** — Notifications icon opens list; pull-to-refresh; tap item; like/dislike if applicable.
6. **Vitals** — Heart icon opens Vitals; last recorded + trend; add vitals form; submit; values LTR in RTL.
7. **Devices** — Devices icon opens Devices; register device; long-press card → Revoke / Rotate token / Copy ID; confirm dialogs.
8. **Lifestyle** — Overflow (⋮) → Lifestyle; context (if any); update form (sleep, steps, calories, stress); submit.

Check: no heavy shadows; neutral colors; consistent 16px horizontal padding on list/content pages; RTL does not break alignment or input.

---

## 6) Verify (CI)

| Command | Purpose |
|--------|---------|
| `flutter analyze` | No new analysis errors. |
| `flutter test` | All existing tests pass. |

---

## 7) Rules Followed

- No new dependencies.
- No backend contract changes.
- Targeted UI fixes only (icons, bubble alignment).
- Single responsibility per widget kept.
- EN default; FA/AR RTL respected.

---

# Stage 20.2 Report: Chat InputBar full-width + Apple-like layout

**Date:** 2025-02-10  
**Context:** Stage 20.0 standardized header icons and RTL bubbles. Chat body uses SafeArea; input bar is Positioned(bottom: keyboardHeight).

---

## 1) Summary (Stage 20.2)

- **Full width:** InputBar root uses `width: double.infinity`; no outer horizontal margin. ChatPage positions it with `Positioned(left: 0, right: 0, bottom: keyboardHeight)` and no Center wrapper, so it spans edge-to-edge within SafeArea. Internal horizontal padding 16 keeps the pill inset.
- **Pill design:** Single-row pill container height 56, border radius 18, subtle border (`AppTheme.borderInactive`), no heavy shadows. Internal padding 12–16; spacing between text field and icons consistent.
- **Icons:** Send = `Icons.arrow_upward_rounded` in circular button (pistachio when enabled, grey when empty). Voice = `Icons.mic_rounded`. Both wrapped in `SizedBox(44, 44)` + `InkResponse` for tap target ≥44×44. Icons remain inside the bar.
- **RTL:** Icon order swaps: in RTL, send is on the “end” side and mic on the “start” side (via `Directionality.of(context)`). Input text direction follows page direction.

---

## 2) Before / After (Stage 20.2)

| Area | Before | After |
|------|--------|--------|
| InputBar width | `(screenWidth - 6) * 0.9` with horizontal margin 3 | `width: double.infinity`, padding 16 inside; no outer margin |
| ChatPage | `Positioned` + `Center` + InputBar | `Positioned(left: 0, right: 0, bottom)` only; no Center |
| Bar shape | ~90px height, radiusMedium, 1.5px border | Pill 56px height, radius 18, 1px subtle border |
| Layout | Column (text row + icon row) | Single Row: Expanded(TextField) \| mic \| send |
| Icons | GestureDetector + fixed sizes | InkResponse in 44×44; Send circle 36px, mic 26px |
| RTL | Fixed order (timer, mic, send) | Order: RTL → [send, mic]; LTR → [mic, send] |

---

## 3) Files Changed (Stage 20.2)

| File | Change |
|------|--------|
| **lib/features/chat/presentation/pages/chat_page.dart** | InputBar no longer wrapped in Center; Positioned uses left: 0, right: 0, bottom: keyboardHeight. |
| **lib/features/chat/presentation/widgets/input_bar.dart** | Full-width root; pill 56×radius 18; single Row with Expanded(TextField), mic, send; 44×44 tap targets (InkResponse); RTL icon order; Send disabled (grey) / enabled (pistachio); recording state (dot + timer). |
| **docs/FRONTEND_STAGE20_REPORT.md** | Stage 20.2 section + manual QA additions. |

---

## 4) Manual QA Additions (Stage 20.2)

Add to the main QA flow (after Chat step):

- **Very narrow screen:** Input bar stays full width; text field wraps or scrolls; mic and send stay visible and tappable.
- **Long message:** Single-line input scrolls horizontally; send/mic remain in place.
- **RTL (fa/ar):** Mic appears on start side, send on end side; input direction follows locale; send disabled/enabled states correct.
- **Keyboard open/close:** Bar stays attached to bottom (above keyboard when open); remains full width; no jump or overlap.
- **Send states:** Send disabled (grey circle) when input empty; enabled (pistachio) when text present; tap sends and clears.

---

## 5) Verify (Stage 20.2)

| Command | Purpose |
|--------|---------|
| `flutter analyze` | No new errors. |
| `flutter test` | All existing tests pass. |

---

# Stage 20.3 Report: Onboarding username-only + soft gender guess

**Date:** 2025-02-10  
**Goal:** Remove password/secret from onboarding; username only. Add soft gender guess from name (FA/AR/EN). Store guessed gender in profile (optional, not shown in UI). Ensure brand name Sedi (EN) / صدی (FA/AR) in copy.

---

## 1) Summary (Stage 20.3)

- **Onboarding & verification:** All password/secret fields and validations removed. Only username (required) is collected. Username is saved to UserProfile and preferences; backend calls still have user context (userId, name).
- **Gender guess:** New `lib/core/utils/gender_guess.dart`: `guessGender(String name, String langCode)` returns `male` / `female` / `unknown`. Heuristics: FA/AR — endings ه, ة (soft female); EN — endings a, e, ie (soft). Default unknown.
- **Storage:** Guessed gender saved in UserProfile as optional `guessedGender` ('male'|'female'|'unknown'); not displayed in UI.
- **API:** `ChatService.setupOnboarding(language, name: name)` — backend receives only `name` (no password).
- **UI copy:** Chat input placeholder uses "Talk to Sedi…" (EN), "با صدی صحبت کنید…" (FA), "تحدث مع صدي…" (AR). Welcome messages already use صدی in FA/AR in `messages.dart`.

---

## 2) Files Changed (Stage 20.3)

| File | Change |
|------|--------|
| **lib/core/utils/gender_guess.dart** | **New.** `guessGender(name, langCode)`, `guessedGenderToValue`, `guessedGenderFromValue`. FA/AR/EN heuristics. |
| **lib/data/models/user_profile.dart** | Added optional `guessedGender`; fromJson/toJson/copyWith. |
| **lib/features/chat/chat_service.dart** | `setupOnboarding(language, name: name)` — payload only `name`; no password. `registerUser` updated. |
| **lib/features/onboarding/presentation/pages/onboarding_page.dart** | Removed password controller/section/validation; username only; call gender guess and save in profile; container height reduced. |
| **lib/features/user_verification/presentation/pages/user_verification_page.dart** | Removed password section/validation; username + language only; gender guess and save; profile without password. |
| **lib/features/chat/presentation/pages/chat_page.dart** | `_inputHint()` locale-aware: Sedi (EN), صدی (FA/AR). |
| **docs/FRONTEND_STAGE20_REPORT.md** | Stage 20.3 section + QA checklist. |

---

## 3) Manual QA Checklist (Stage 20.3)

1. **Onboarding:** Open app (clear profile if needed). Onboarding shows only "Name" field; no password. Enter name → submit → navigates to Chat. Profile has name, userId, isVerified; no security password.
2. **Verification dialog:** From Chat (or wherever verification is shown). Dialog shows language + name only; no password. Submit → profile updated, dialog closes.
3. **Chat placeholder:** In EN locale placeholder is "Talk to Sedi…"; switch to FA (or device FA) → "با صدی صحبت کنید…"; AR → "تحدث مع صدي…".
4. **Navigation:** Intro → Onboarding → Chat flow unchanged; no broken routes.
5. **Backend:** Onboarding API receives only `{ "name": "..." }`; backend already supports username-only.

---

## 4) Verify (Stage 20.3)

| Command | Purpose |
|--------|---------|
| `flutter analyze` | No new errors. |
| `flutter test` | All existing tests pass. |

*(If pub get fails due to network/auth, run the above in an environment with access to pub.dev.)*

---

# Stage 20.4 Report: Fix Chat 422 – align /interact payload with backend

**Date:** 2025-02-10  
**Goal:** Ensure chat requests match backend ChatRequest (user_id int, message string) to eliminate HTTP 422. Add safe debug logging and 422 error message. No secrets logged.

---

## 1) Summary (Stage 20.4)

- **Backend contract:** POST `/interact/chat` expects JSON body `{ "user_id": int, "message": string }` only (no query params, no language/name/secret in body). Language is detected from message content on the backend.
- **InteractRequest:** DTO with `userId` (int), `message` (string), `toJson()` → exact backend shape.
- **Flow:** ChatController → ChatService.sendMessage → ChatRepository.sendChat(InteractRequest) → http.post with JSON body. No query params for chat.
- **422 handling:** On 422, log endpoint, payload keys, and response detail; set `ChatLastErrorDump`; return `REQUEST_FORMAT_ERROR`; UI shows "Request format issue. Please try again." (EN) and localized FA/AR.
- **Debug helper:** `lib/core/debug/chat_last_error_dump.dart` stores last error (endpoint, payloadKeys, responseMessage, statusCode) in memory for quick copy during testing. Not persisted; no secrets.
- **AppConfig:** baseUrl and useLocalMode unchanged; useLocalMode false for real backend tests.

---

## 2) Files Changed (Stage 20.4)

| File | Change |
|------|--------|
| **lib/data/dto/interact_request.dart** | Implemented: `InteractRequest(userId, message)`, `toJson()` → `user_id`, `message`. |
| **lib/data/dto/interact_response.dart** | Implemented: `InteractResponse.fromJson` for parsing chat response (message, language, user_id, etc.). |
| **lib/data/repositories/chat_repository.dart** | Implemented: `sendChat(InteractRequest)` → POST /interact/chat with JSON body; returns `ChatRepositoryResult(statusCode, body)`. No secrets in logs. |
| **lib/features/chat/chat_service.dart** | Builds `InteractRequest`, calls `sendChat(request)`; JSON body only; 422 → dump + "Request format issue. Please try again."; safe debug logs (endpoint, payload keys). |
| **lib/features/chat/state/chat_controller.dart** | Handles `REQUEST_FORMAT_ERROR:` with EN/FA/AR message. |
| **lib/core/debug/chat_last_error_dump.dart** | **New.** In-memory last error: endpoint, payloadKeys, responseMessage, statusCode; `summary` getter for logs. |
| **docs/FRONTEND_STAGE20_REPORT.md** | Stage 20.4 section. |

---

## 3) Verify (Stage 20.4)

| Command | Purpose |
|--------|---------|
| `flutter analyze` | No new errors. |
| `flutter test` | All existing tests pass. |

**Manual:** Send a short message → should return 200 and assistant response. If 422, debug log shows endpoint, payload keys, and response detail; `ChatLastErrorDump.summary` can be copied for diagnosis.

---

# Stage 20.5 Report: Brand naming lock – Sedi (EN) / صدی (FA/AR)

**Date:** 2025-02-10  
**Goal:** Consistent brand name everywhere: EN = "Sedi", FA/AR = "صدی". Centralized via helper; no other spellings in UI, notifications, onboarding, or intro.

---

## 1) Summary (Stage 20.5)

- **Helper:** `lib/core/utils/brand_name.dart` — `sediBrandName(String langCode)` returns `'صدی'` for fa/ar and `'Sedi'` otherwise.
- **Replaced:** Welcome message (AppMessages), chat input placeholder, SediHeader fallback text, chat history mock copy, devices hint, notification channel name/description. All use `sediBrandName(lang)` or `sediBrandName('en')` where locale is fixed (e.g. notifications).
- **Test:** `test/brand_name_test.dart` — fa/ar → صدی, en → Sedi, unknown → Sedi.

---

## 2) Files changed (Stage 20.5)

| File | Change |
|------|--------|
| **lib/core/utils/brand_name.dart** | **New.** `sediBrandName(langCode)`. |
| **lib/core/utils/messages.dart** | `getWelcomeMessage` uses `sediBrandName(language)` for brand in FA/AR/EN strings. |
| **lib/features/chat/presentation/pages/chat_page.dart** | `_inputHint()` uses `sediBrandName(lang)`. |
| **lib/features/chat/presentation/widgets/sedi_header.dart** | Fallback text uses `sediBrandName(Localizations.localeOf(context).languageCode)`. |
| **lib/features/chat/presentation/pages/chat_history_page.dart** | Mock lastMessage uses `sediBrandName('en')`. |
| **lib/features/devices/presentation/pages/devices_page.dart** | Hint uses `sediBrandName('en')`. |
| **lib/core/notifications/local_notifications_service.dart** | Channel name and descriptions use `sediBrandName('en')`. |
| **test/brand_name_test.dart** | **New.** Tests fa/ar → صدی, en → Sedi. |
| **docs/FRONTEND_STAGE20_REPORT.md** | Stage 20.5 section. |

---

## 3) Verify (Stage 20.5)

| Command | Purpose |
|--------|---------|
| `flutter analyze` | No new errors. |
| `flutter test test/brand_name_test.dart` | Brand name tests pass. |

---

# Stage 20.6 Report: Brand enforcement – FA/AR must show "صدی"; no "سدی"

**Date:** 2025-02-10  
**Goal:** Ensure brand is consistent: EN = "Sedi", FA/AR = "صدی". No "سدی" (wrong spelling) anywhere in UI, intro, chat fallback, notifications, onboarding.

---

## 1) Summary (Stage 20.6)

- **Search:** Repo searched for "سدی" — no occurrences found. All user-facing brand strings already use `sediBrandName(langCode)` from Stage 20.5.
- **Helper:** `lib/core/utils/brand_name.dart` — comment added: do not use "سدی"; always use helper for FA/AR. Returns "صدی" for fa/ar.
- **Test:** `test/brand_name_test.dart` — added explicit checks that fa/ar return "صدی" and not "سدی"; fa/ar => صدی, en => Sedi.
- **Coverage:** Welcome (AppMessages), chat placeholder, SediHeader fallback, chat history mock, devices hint, notification channel — all use `sediBrandName()`. Intro has no brand text; offline/error messages in ChatController are generic (no brand name).

---

## 2) Files changed (Stage 20.6)

| File | Change |
|------|--------|
| **lib/core/utils/brand_name.dart** | Comment: do not use "سدی"; use helper. Inline note (correct: صدی). |
| **test/brand_name_test.dart** | Tests: fa/ar return "صدی" and `isNot('سدی')`; en => Sedi. |
| **docs/FRONTEND_STAGE20_REPORT.md** | Stage 20.6 section. |

---

## 3) Verify (Stage 20.6)

| Command | Purpose |
|--------|---------|
| `flutter analyze` | No new errors. |
| `flutter test test/brand_name_test.dart` | Brand tests pass (fa/ar => صدی, en => Sedi, never سدی). |

**Manual:** Run app in FA or AR locale; confirm all user-visible strings show "صدی" and never "سدی".

---

# Stage 20.7 Report: Approved Sedi intro greeting (FA/EN/AR) + once per user, no duplicate

**Date:** 2025-02-10  
**Goal:** Replace greeting with product-approved intro text. FA/AR use "صدی", EN use "Sedi". Greeting shown once per user (persisted flag); no reinsert on app reopen.

---

## 1) Summary (Stage 20.7)

- **greeting_templates.dart:** New file with approved FA/EN/AR intro text. `getIntroGreeting(langCode)` returns the exact copy (FA: گجت، مراقبت پیوسته، صدی; EN: Sedi, specialized gadgets, continuous; AR: صدی).
- **ChatController:** Uses templates instead of backend for first-time greeting. Calls `_showIntroGreetingOnce()`: if `UserPreferences.hasSeenIntroGreeting()` is true, skips (no duplicate on reopen); else shows `getIntroGreeting(lang)`, then sets `setHasSeenIntroGreeting(true)`. Language from profile or UserPreferences.
- **UserPreferences:** Added `hasSeenIntroGreeting` / `setHasSeenIntroGreeting` for persistence.
- **Tests:** `test/greeting_templates_test.dart` — FA/AR contain "صدی" and not "سدی"; EN contains "Sedi"; FA mentions "گجت" and "مراقبت پیوسته"; EN mentions "specialized gadgets" and "continuous".

---

## 2) Files changed (Stage 20.7)

| File | Change |
|------|--------|
| **lib/features/chat/logic/greeting_templates.dart** | **New.** Approved FA/EN/AR intro; `getIntroGreeting(langCode)`. |
| **lib/core/utils/user_preferences.dart** | `hasSeenIntroGreeting`, `setHasSeenIntroGreeting`. |
| **lib/features/chat/state/chat_controller.dart** | Initialize uses `_showIntroGreetingOnce()` (templates + flag); no backend greeting for intro. |
| **test/greeting_templates_test.dart** | **New.** Assert FA/AR صدی, EN Sedi, FA گجت/مراقبت پیوسته, EN specialized gadgets/continuous. |
| **docs/FRONTEND_STAGE20_REPORT.md** | Stage 20.7 section. |

---

## 3) Verify (Stage 20.7)

| Command | Purpose |
|--------|---------|
| `flutter analyze` | No new errors. |
| `flutter test test/greeting_templates_test.dart` | Greeting template tests pass. |

**Manual:** Fresh install → greeting shows once. Reopen app → no duplicate greeting. FA/AR show "صدی" in intro text.

---

# Stage 20.8 Report: App icon fix – Sedi circular logo on Android/iOS

**Date:** 2025-02-10  
**Goal:** Launcher icon = white circle background + pistachio-green Sedi/صدی logo centered. Use flutter_launcher_icons; commit generated assets; bump version so devices update icon.

---

## 1) Summary (Stage 20.8)

- **Source icon:** `assets/images/sedi_app_icon.png` (square 1024×1024 recommended; visually: white circle + pistachio logo centered). Replace this file if the design does not match.
- **pubspec.yaml:** `flutter_launcher_icons` config already points to `assets/images/sedi_app_icon.png`; android + ios true.
- **Version bumped:** `1.0.0+1` → `1.0.0+2` so Android versionCode increments and reinstall/update shows new icon.
- **Doc:** `docs/APP_ICON.md` — steps to run `flutter pub get` and `dart run flutter_launcher_icons`, commit generated mipmap and iOS AppIcon, and verify.

---

## 2) Files changed (Stage 20.8)

| File | Change |
|------|--------|
| **pubspec.yaml** | version 1.0.0+1 → 1.0.0+2. |
| **docs/APP_ICON.md** | **New.** Icon source, config, generate commands, version bump, verify. |
| **docs/FRONTEND_STAGE20_REPORT.md** | Stage 20.8 section. |

---

## 3) Generated assets (commit after running launcher_icons)

After running `dart run flutter_launcher_icons`, commit:

- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png` (and Contents.json if changed)

---

## 4) Verify (Stage 20.8)

| Command | Purpose |
|--------|---------|
| `flutter analyze` | No new errors. |
| `flutter test` | All tests pass. |
| `flutter build apk --debug` | Debug APK builds. |

**Manual:** Uninstall old app, install fresh build, confirm launcher icon shows white circle + pistachio logo.
