# دستورات Push به GitHub

## روش 1: استفاده از اسکریپت (پیشنهادی)

```powershell
.\push-commands.ps1
```

## روش 2: اجرای دستی دستورات

### مرحله 1: اضافه کردن فایل‌ها
```powershell
git add -A
```

### مرحله 2: بررسی وضعیت
```powershell
git status
```

### مرحله 3: ایجاد Commit
```powershell
git commit -m "chore: تمیزسازی پروژه و آماده‌سازی برای GitHub Actions

- حذف pubspec.lock (استفاده از pub.dev)
- حذف فایل‌های .iml اضافی
- حذف پوشه قدیمی com/example/frontend
- به‌روزرسانی نام‌ها به sedi_app
- تنظیمات Android استاندارد Flutter
- اضافه کردن GitHub Actions workflows
- بهبود کد و documentation"
```

### مرحله 4: بررسی Remote
```powershell
git remote -v
```

اگر remote تنظیم نشده:
```powershell
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
```

### مرحله 5: Push به GitHub
```powershell
git push -u origin main
```

یا اگر branch دیگری دارید:
```powershell
git push -u origin YOUR_BRANCH_NAME
```

## روش 3: استفاده از اسکریپت موجود

```powershell
.\push-to-github.ps1
```

## نکات مهم

1. **قبل از push** مطمئن شوید که:
   - همه تغییرات commit شده‌اند
   - remote repository تنظیم شده است
   - branch فعلی را می‌شناسید

2. **بعد از push**:
   - GitHub Actions به صورت خودکار اجرا می‌شود
   - می‌توانید در بخش Actions > Artifacts، APK را دانلود کنید

3. **در صورت خطا**:
   - اگر نیاز به pull دارید: `git pull origin main`
   - اگر conflict دارید: ابتدا resolve کنید
   - اگر دسترسی ندارید: تنظیمات GitHub را بررسی کنید

