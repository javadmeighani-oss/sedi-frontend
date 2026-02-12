# CI Android Build and Install (Stage 16.6.7)

How to obtain and install the Android APK produced by GitHub Actions.

---

## Where to Download

1. Push to `main`, `master`, or `develop` (with changes under `frontend/`), or trigger manually via **Actions → Build Flutter Frontend → Run workflow**.
2. Go to **GitHub → Actions → Build Flutter Frontend**.
3. Open the latest successful run.
4. Under **Artifacts**, download `sedi-android-apk-<commit-sha>`.
5. Extract the ZIP; it contains `app-release.apk`.

---

## Install on Android

### Recommended: adb install

```bash
# Connect device via USB, enable USB debugging
adb devices

# Install (replace path with your extracted APK)
adb install -r path/to/app-release.apk
```

- `-r` replaces an existing install (keeps data if the app supports it).
- For a clean install: uninstall first, then `adb install path/to/app-release.apk`.

### Manual Install

1. Copy `app-release.apk` to the device (USB, email, cloud, etc.).
2. On the device, open the file and tap **Install**.
3. If prompted, enable **Install from unknown sources** for the app or source (Settings → Security).

---

## Common Pitfalls

| Issue | Solution |
|-------|----------|
| "App not installed" | Uninstall the previous build; debug/release signatures differ. |
| "Unknown sources" blocked | Enable installation from the source app or file manager in Settings → Security. |
| "Parse error" | Ensure the APK was fully downloaded and not corrupted. Re-download and retry. |
| Device not found (adb) | Enable USB debugging in Developer options; re-authorize the computer. |

---

## Build Configuration

- **Flutter**: 3.24.0 (stable)
- **Java**: 17 (Temurin)
- **Determinism**: `pubspec.lock` is used; pub and Gradle caches are cached in CI.
