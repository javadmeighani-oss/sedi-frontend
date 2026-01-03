# راهنمای ایجاد Release Keystore برای Sedi

**مشکل:** Google Play Protect APK را به عنوان "harmful" تشخیص می‌دهد چون با debug signing build شده است.

**راه حل:** ایجاد یک release keystore و استفاده از آن برای signing APK.

---

## روش 1: ایجاد Keystore محلی

### گام 1: ایجاد Keystore

```bash
cd frontend/android
keytool -genkey -v -keystore sedi-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias sedi
```

**سوالات:**
- Password: یک password قوی انتخاب کنید (حداقل 8 کاراکتر)
- Name: Sedi
- Organizational Unit: Development
- Organization: Rimiya Design Studio
- City: [شهر شما]
- State: [استان شما]
- Country: IR (یا کد کشور شما)

### گام 2: ایجاد فایل key.properties

در `frontend/android/` فایل `key.properties` ایجاد کنید:

```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=sedi
storeFile=sedi-release-key.jks
```

**⚠️ مهم:** این فایل را به git اضافه نکنید! (در `.gitignore` است)

### گام 3: Build با Release Signing

```bash
flutter build apk --release
```

---

## روش 2: استفاده در GitHub Actions

### گام 1: ایجاد Keystore (یک بار)

```bash
keytool -genkey -v -keystore sedi-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias sedi
```

### گام 2: تبدیل به Base64

```bash
# Windows PowerShell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("sedi-release-key.jks")) | Out-File keystore-base64.txt

# Linux/Mac
base64 -i sedi-release-key.jks -o keystore-base64.txt
```

### گام 3: اضافه کردن به GitHub Secrets

1. به GitHub repository بروید
2. Settings → Secrets and variables → Actions
3. Secrets زیر را اضافه کنید:
   - `KEYSTORE_FILE`: محتوای base64 keystore
   - `KEYSTORE_PASSWORD`: password keystore
   - `KEY_ALIAS`: sedi
   - `KEY_PASSWORD`: password key

### گام 4: به‌روزرسانی Workflow

Workflow به‌روزرسانی شده است تا از environment variables استفاده کند.

---

## روش 3: راه حل موقت (بدون Keystore)

اگر نمی‌خواهید keystore ایجاد کنید، می‌توانید:

1. **در تنظیمات موبایل:**
   - Settings → Security → Install unknown apps
   - اجازه نصب از منبع مورد نظر را بدهید

2. **غیرفعال کردن Google Play Protect:**
   - Settings → Google → Security → Google Play Protect
   - "Scan apps with Play Protect" را خاموش کنید

**⚠️ توجه:** این روش فقط برای تست است و برای production توصیه نمی‌شود.

---

## بررسی Signing

بعد از build، می‌توانید signing را بررسی کنید:

```bash
# Windows
jarsigner -verify -verbose -certs app-release.apk

# یا با apksigner (Android SDK)
apksigner verify --verbose app-release.apk
```

---

## نکات مهم

1. ✅ **Keystore را backup کنید** - اگر گم شود، نمی‌توانید app را update کنید
2. ✅ **Password را در جای امن نگه دارید**
3. ✅ **هرگز keystore را به git commit نکنید**
4. ✅ **برای production حتماً از release keystore استفاده کنید**

---

## فایل‌های مرتبط

- `frontend/android/app/build.gradle` - Signing configuration
- `frontend/android/key.properties.example` - Example key properties
- `frontend/android/.gitignore` - Keystore files ignored

---

**نکته:** بعد از ایجاد keystore و build جدید، Google Play Protect دیگر warning نمی‌دهد.

