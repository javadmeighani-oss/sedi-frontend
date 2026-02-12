# Push Notifications v1 – Android Setup & Testing

Stage 16.6: FCM-based push notifications with action buttons (LIKE, DISLIKE, OPEN_CHAT).

## Adding google-services.json Locally

**Do NOT commit `google-services.json` to the repository.** It contains project-specific configuration.

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create one)
3. Add an Android app with package name `com.sedi.app`
4. Download `google-services.json`
5. Place it in `frontend/android/app/google-services.json`

Without this file, the app will run but Firebase/FCM setup will be skipped (graceful fallback). CI creates a stub automatically when the file is missing.

## Android Configuration

- **Permissions**: `POST_NOTIFICATIONS` (Android 13+) is declared in `AndroidManifest.xml`
- **Default channel**: `engagement` is set as FCM default notification channel
- **Channels**: morning, engagement, health_alert (created at runtime)

## Channel Behavior

| Channel | Importance | Behavior |
|---------|------------|----------|
| **health_alert** | HIGH | Heads-up, vibration + sound. For urgent health care alerts. |
| **engagement** | DEFAULT | Non-intrusive nudges. Sound on, no vibration. |
| **morning** | LOW | No heads-up. Minimal disruption for daily brief. |

Users can override per-channel settings (sound, vibration, importance) in Android system settings: **Settings → Apps → Sedi → Notifications**.

## Testing on a Real Device

### 1. Build and Install

```bash
cd frontend
flutter pub get
flutter run
```

### 2. Login

Complete onboarding/verification so the app has a `userId`. The FCM token is registered with the backend only when a user is logged in.

On logout, the token is unregistered via `POST /notifications/push/unregister` to prevent misdelivery to the previous user.

### 3. Verify Token Registration

- After login, check backend logs or network inspector
- `POST /notifications/push/register` should be called with `user_id`, `fcm_token`, `platform: android`

### 4. Send a Test Push

**Option A – Firebase Console**

1. Go to Firebase Console → Cloud Messaging → Create your first campaign (or New campaign)
2. Compose notification: title, body
3. Additional options → Custom data: add `notification_id`, `channel`, `deeplink_url`, `actions` (optional)
4. Send test message: add your device FCM token (retrieve via `adb logcat` or a debug print)

**Option B – Backend**

- Use the backend’s notification delivery pipeline
- Create a notification via scheduler or API and run `POST /notifications/deliver_pending`

### 5. Verify Behavior

- **Foreground**: Notification shows with action buttons
- **Background/Terminated**: Same notification via system tray
- **Actions**:
  - LIKE / DISLIKE → Feedback sent to `POST /notifications/{id}/feedback`, notification dismissed
  - OPEN_CHAT → Feedback sent, app opens ChatPage

### 6. Feedback API

Tapping LIKE, DISLIKE, or OPEN_CHAT sends:

```
POST /notifications/{notification_id}/feedback
Body: { "action": "like" | "dislike" | "open_chat" | "dismissed", "client_ts": "..." }
```

## Deep Link

- Format: `sedi://chat?from=notif&id={notification_id}`
- Tapping the notification or OPEN_CHAT navigates to ChatPage with `fromNotification: true` and `notificationId`.

## Chat-Based Notification Settings (Stage 16.6.6)

Users can manage timezone and quiet hours via chat commands. Use the schedule icon (⏱) in the Chat header to open a quick actions bottom sheet, or type commands directly:

**Set timezone:**
- en: `set timezone Asia/Tehran` / `timezone: Asia/Tehran`
- fa: `تایم زون: Asia/Tehran`
- ar: `المنطقة الزمنية: Asia/Tehran`

**Set quiet hours:**
- en: `quiet hours 22:00-08:00` / `do not disturb 22:00-08:00`
- fa: `ساعات سکوت 22:00-08:00`
- ar: `ساعات الهدوء 22:00-08:00`

**Disable quiet hours:**
- en: `disable quiet hours` / `quiet hours off`
- fa: `خاموش کردن ساعات سکوت`
- ar: `إيقاف ساعات الهدوء`
