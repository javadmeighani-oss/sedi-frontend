# ============================================
# دستورات Push به GitHub برای پروژه Sedi
# ============================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Sedi - Push to GitHub" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# مرحله 1: بررسی وضعیت Git
Write-Host "📊 مرحله 1: بررسی وضعیت Git..." -ForegroundColor Yellow
git status
Write-Host ""

# مرحله 2: اضافه کردن همه فایل‌ها
Write-Host "➕ مرحله 2: اضافه کردن فایل‌ها به Git..." -ForegroundColor Yellow
git add -A
Write-Host "✅ فایل‌ها اضافه شدند" -ForegroundColor Green
Write-Host ""

# مرحله 3: نمایش فایل‌های آماده برای commit
Write-Host "📋 مرحله 3: فایل‌های آماده برای commit:" -ForegroundColor Cyan
git status --short
Write-Host ""

# مرحله 4: ایجاد commit
Write-Host "💾 مرحله 4: ایجاد commit..." -ForegroundColor Yellow
$commitMessage = "chore: تمیزسازی پروژه و آماده‌سازی برای GitHub Actions

- حذف pubspec.lock (استفاده از pub.dev)
- حذف فایل‌های .iml اضافی
- حذف پوشه قدیمی com/example/frontend
- به‌روزرسانی نام‌ها به sedi_app
- تنظیمات Android استاندارد Flutter
- اضافه کردن GitHub Actions workflows
- بهبود کد و documentation"

git commit -m $commitMessage

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ خطا در commit!" -ForegroundColor Red
    Write-Host "لطفاً مشکل را بررسی کنید." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Commit با موفقیت ایجاد شد" -ForegroundColor Green
Write-Host ""

# مرحله 5: بررسی remote repository
Write-Host "🌐 مرحله 5: بررسی remote repository..." -ForegroundColor Yellow
$remoteUrl = git remote get-url origin 2>$null

if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  هیچ remote repository تنظیم نشده است!" -ForegroundColor Yellow
    Write-Host "لطفاً ابتدا remote را تنظیم کنید:" -ForegroundColor Yellow
    Write-Host "  git remote add origin <URL>" -ForegroundColor White
    exit 1
}

Write-Host "✅ Remote repository: $remoteUrl" -ForegroundColor Green
Write-Host ""

# مرحله 6: بررسی branch فعلی
Write-Host "🌿 مرحله 6: بررسی branch..." -ForegroundColor Yellow
$currentBranch = git branch --show-current
Write-Host "Branch فعلی: $currentBranch" -ForegroundColor Cyan
Write-Host ""

# مرحله 7: Push به GitHub
Write-Host "🚀 مرحله 7: Push به GitHub..." -ForegroundColor Yellow
Write-Host "Branch: $currentBranch" -ForegroundColor Cyan
Write-Host ""

# سوال نهایی
$finalConfirm = Read-Host "آیا مطمئن هستید که می‌خواهید push کنید؟ (y/n)"
if ($finalConfirm -ne "y" -and $finalConfirm -ne "Y") {
    Write-Host "❌ Push لغو شد." -ForegroundColor Red
    exit 0
}

# اجرای push
Write-Host "در حال push..." -ForegroundColor Yellow
git push -u origin $currentBranch

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  ✅ Push با موفقیت انجام شد!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "🔗 GitHub Actions workflow باید به صورت خودکار اجرا شود." -ForegroundColor Cyan
    Write-Host "📱 APK در بخش Actions > Artifacts قابل دانلود است." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "برای مشاهده workflow:" -ForegroundColor Yellow
    Write-Host "  https://github.com/YOUR_USERNAME/YOUR_REPO/actions" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "❌ خطا در push! لطفاً مشکل را بررسی کنید." -ForegroundColor Red
    Write-Host ""
    Write-Host "مشکلات احتمالی:" -ForegroundColor Yellow
    Write-Host "  1. اتصال به اینترنت" -ForegroundColor White
    Write-Host "  2. دسترسی به repository" -ForegroundColor White
    Write-Host "  3. نیاز به pull قبل از push" -ForegroundColor White
    exit 1
}

