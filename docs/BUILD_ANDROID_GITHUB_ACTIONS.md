# ساخت APK اندروید با GitHub Actions و تست روی موبایل

برای اینکه بتوانید اپ صدی را روی گوشی اندروید تست کنید، کافی است کد را به گیت‌هاب پوش کنید؛ GitHub Actions به‌صورت خودکار APK را می‌سازد و شما آن را دانلود و نصب می‌کنید.

---

## ۱) پوش کردن کد به گیت‌هاب

### اگر مخزن شما کل پروژه (Demo با پوشه‌ی frontend) است

از ریشه‌ی پروژه:

```bash
cd "D:\Rimiya Design Studio\Sedi\software\Demo"
git add .
git commit -m "build: frontend for Android test"
git push origin main
```

(در صورت استفاده از برنچ دیگر مثل `develop` یا `master`، همان را به‌جای `main` بگذارید.)

### اگر مخزن فقط همین پوشه‌ی frontend است

در این حالت ریشه‌ی ریپو باید همان پوشه‌ی `frontend` باشد و پوشه‌ی `.github` داخل آن قرار دارد:

```bash
cd "D:\Rimiya Design Studio\Sedi\software\Demo\frontend"
git add .
git commit -m "build: Android APK"
git push origin main
```

---

## ۲) اجرای workflow

- با **پوش** به برنچ‌های `main`، `master` یا `develop`، workflow به‌صورت خودکار اجرا می‌شود.
- در مخزن **کل پروژه**، فقط وقتی فایل‌های داخل `frontend/**` عوض شده باشند اجرا می‌شود.
- برای اجرای دستی: در گیت‌هاب بروید به **Actions** → workflow با نام **Build Flutter Frontend** یا **Build Flutter Frontend - Android** → **Run workflow** و برنچ را انتخاب کنید.

---

## ۳) دانلود APK

1. در گیت‌هاب به تب **Actions** بروید.
2. آخرین اجرای موفق (تیک سبز) را باز کنید.
3. پایین صفحه در بخش **Artifacts** فایل **sedi-android-apk** را ببینید.
4. روی آن کلیک کنید تا فایل `app-release.apk` (یا یک آرشیو حاوی آن) دانلود شود.
5. در صورت آرشیو (zip)، آن را باز کنید و فایل APK را بیرون بکشید.

---

## ۴) نصب روی گوشی اندروید

- APK را به گوشی منتقل کنید (اتصال USB، ایمیل، ابر، یا همان دانلود مستقیم روی گوشی).
- در اندروید: **Settings → Security** و گزینه **Install from unknown sources** (یا **Unknown apps**) را برای مرورگر/فایل‌منیجر مورد استفاده مجاز کنید.
- فایل `app-release.apk` را باز کنید و **Install** بزنید.
- بعد از نصب، اپ «صدی» را اجرا کنید و روی موبایل تست کنید.

---

## ۵) در صورت خطا در build

- در همان run در **Actions** لاگ هر step را باز کنید و خطا را ببینید.
- معمولاً خطاهای رایج: وابستگی‌های Flutter (`flutter pub get`)، نسخه Java، یا خطای تحلیل کد (`flutter analyze`). با رفع آن‌ها و یک commit جدید دوباره پوش کنید تا build دوباره اجرا شود.

---

## خلاصه

| مرحله | کار |
|--------|-----|
| ۱ | `cd` به ریشه پروژه یا به پوشه frontend (بسته به نوع مخزن) |
| ۲ | `git add .` و `git commit` و `git push origin main` |
| ۳ | در گیت‌هاب → Actions → آخرین run موفق |
| ۴ | دانلود Artifact با نام **sedi-android-apk** |
| ۵ | نصب APK روی گوشی اندروید و تست اپ |

با این مراحل می‌توانید فرانت را در GitHub Actions پوش کنید و برنامه را روی موبایل اندرویدی تست کنید.
