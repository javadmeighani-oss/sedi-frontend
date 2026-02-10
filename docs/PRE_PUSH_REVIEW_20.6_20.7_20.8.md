# Pre-Push Review: Stages 20.6 / 20.7 / 20.8

**Date:** 2025-02-10  
**Project:** `frontend/`

---

## Step 1 — Brand Verification (20.6) ✅ PASS

| Check | Result |
|-------|--------|
| Search for "سدی" in **lib/** and user-facing code | **None.** Only in docs, tests (asserting absence), and comments in `brand_name.dart` / `greeting_templates.dart`. |
| FA/AR hardcoded "Sedi" | **None.** Only EN greeting and code identifiers (SediHeader, _addSediMessage, etc.) use "Sedi". |
| FA/AR → "صدی", EN → "Sedi" | **Correct.** `brand_name.dart` returns `'صدی'` for fa/ar, `'Sedi'` for en. |
| Helper used where applicable | **Yes.** Greeting uses `getIntroGreeting(lang)`; other UI uses `sediBrandName(langCode)`. |

**Unit test:** `flutter test test/brand_name_test.dart` — **not run in this environment** (pub.dev authorization failed). Run locally before push.

---

## Step 2 — Intro / Greeting Verification (20.7) ✅ PASS

| Check | Result |
|-------|--------|
| **FA** includes "مراقبت پیوسته" | ✅ `_greetingFa` contains it. |
| **FA** includes "گجت‌های تخصصی صدی" | ✅ Present. |
| **FA** includes "حمایت عاطفی" | ✅ Present. |
| **EN** includes "specialized gadgets" | ✅ Present. |
| **EN** includes "continuous health monitoring" | ✅ Present. |
| **EN** includes "trusted friend" | ✅ Present. |
| FA/AR use "صدی", EN uses "Sedi" | ✅ Verified in `greeting_templates.dart`. |
| Greet-once logic | ✅ `UserPreferences.hasSeenIntroGreeting()` / `setHasSeenIntroGreeting(true)`; key `has_seen_intro_greeting`. `_showIntroGreetingOnce()` skips if already seen; no reinsert on reopen. |

**Unit test:** `flutter test test/greeting_templates_test.dart` — **not run in this environment**. Run locally before push.

---

## Step 3 — App Icon Verification (20.8) ✅ PASS

| Check | Result |
|-------|--------|
| Source icon exists | ✅ `assets/images/sedi_app_icon.png` |
| pubspec version | ✅ `1.0.0+2` |
| flutter_launcher_icons | ✅ `image_path: "assets/images/sedi_app_icon.png"`, android + ios true |
| Android generated | ✅ `mipmap-hdpi`, `mdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi` each have `ic_launcher.png` |
| iOS generated | ✅ `AppIcon.appiconset/` has Contents.json and Icon-App-*.png set |

**Git:** `assets/images/sedi_app_icon.png` and other Stage 20 files are currently untracked/modified. Include them in the commit (see Step 5).

---

## Step 4 — Global Checks ⚠️ NOT RUN (Environment)

| Command | Result |
|---------|--------|
| `flutter analyze` | **Failed** — `Insufficient permissions to the resource at the https://pub.dev package repository` (dependency resolution). |
| `flutter test` | **Failed** — Same pub.dev authorization issue. |

**Action required:** Run the following **locally** before push:

```bash
cd frontend
flutter pub get
flutter analyze
flutter test
```

If any of these fail → **do not push**; fix and re-run.

---

## Step 5 — Commit & Push

**Status:** **Do NOT push from this environment** because:

1. `flutter analyze` and `flutter test` could not be run here (pub.dev auth).
2. Per instructions: *"If any error appears → STOP and report."*

**When running locally and all checks pass:**

```bash
cd "D:\Rimiya Design Studio\Sedi\software\Demo\frontend"
git status
git add .
git commit -m "Stage 20 complete: brand lock, approved intro, app icon (Freeze ready)"
git push
```

---

## Summary

| Item | Status |
|------|--------|
| **Brand** | ✅ OK (no "سدی" in UI; helper used; FA/AR=صدی, EN=Sedi) |
| **Intro** | ✅ OK (approved text; greet-once; flag `has_seen_intro_greeting`) |
| **Icon** | ✅ OK (source + config + version 1.0.0+2; generated assets present) |
| **Tests** | ⚠️ **PASS not verified here** — run `flutter test` locally |
| **Push** | ❌ **Not done** — run `flutter analyze` and `flutter test` locally first; then commit and push. |

**No blocking code/asset issues found.** Only blocker is verification of analyze and test in an environment with pub.dev access.
