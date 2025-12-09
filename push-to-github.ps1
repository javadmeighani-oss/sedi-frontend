# ============================================
# اسکریپت Push به GitHub برای پروژه Sedi
# ============================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Sedi - Push to GitHub" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# بررسی اینکه آیا در یک Git repository هستیم
if (-not (Test-Path ".git")) {
    Write-Host "❌ خطا: این دایرکتوری یک Git repository نیست!" -ForegroundColor Red
    Write-Host "ابتدا با دستور زیر repository را initialize کنید:" -ForegroundColor Yellow
    Write-Host "  git init" -ForegroundColor White
    exit 1
}

# نمایش وضعیت فعلی
Write-Host "📊 بررسی وضعیت Git..." -ForegroundColor Yellow
git status
Write-Host ""

# سوال از کاربر برای ادامه
$continue = Read-Host "آیا می‌خواهید ادامه دهید؟ (y/n)"
if ($continue -ne "y" -and $continue -ne "Y") {
    Write-Host "❌ عملیات لغو شد." -ForegroundColor Red
    exit 0
}

# پاک‌سازی و دریافت وابستگی‌ها
Write-Host ""
Write-Host "🧹 پاک‌سازی پروژه..." -ForegroundColor Yellow
flutter clean

Write-Host ""
Write-Host "📦 دریافت وابستگی‌ها..." -ForegroundColor Yellow
flutter pub get

# بررسی وضعیت Flutter
Write-Host ""
Write-Host "🔍 بررسی وضعیت Flutter..." -ForegroundColor Yellow
flutter doctor -v

# اضافه کردن همه فایل‌ها
Write-Host ""
Write-Host "➕ اضافه کردن فایل‌ها به Git..." -ForegroundColor Yellow
git add .

# نمایش فایل‌های اضافه شده
Write-Host ""
Write-Host "📋 فایل‌های آماده برای commit:" -ForegroundColor Cyan
git status --short

# دریافت پیام commit
Write-Host ""
$commitMessage = Read-Host "پیام commit را وارد کنید (یا Enter برای استفاده از پیام پیش‌فرض)"
if ([string]::IsNullOrWhiteSpace($commitMessage)) {
    $commitMessage = "chore: تنظیمات Android و آماده‌سازی برای GitHub Actions"
}

# Commit
Write-Host ""
Write-Host "💾 ایجاد commit..." -ForegroundColor Yellow
git commit -m $commitMessage

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ خطا در commit! ممکن است تغییری برای commit وجود نداشته باشد." -ForegroundColor Red
    Write-Host "آیا می‌خواهید ادامه دهید و push کنید؟ (y/n)" -ForegroundColor Yellow
    $continuePush = Read-Host
    if ($continuePush -ne "y" -and $continuePush -ne "Y") {
        exit 1
    }
}

# بررسی remote repository
Write-Host ""
Write-Host "🌐 بررسی remote repository..." -ForegroundColor Yellow
$remoteUrl = git remote get-url origin 2>$null

if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  هیچ remote repository تنظیم نشده است!" -ForegroundColor Yellow
    $setupRemote = Read-Host "آیا می‌خواهید remote را تنظیم کنید؟ (y/n)"
    if ($setupRemote -eq "y" -or $setupRemote -eq "Y") {
        $remoteUrl = Read-Host "URL repository GitHub را وارد کنید (مثال: https://github.com/username/sedi-app.git)"
        git remote add origin $remoteUrl
        Write-Host "✅ Remote repository اضافه شد." -ForegroundColor Green
    } else {
        Write-Host "❌ بدون remote repository نمی‌توان push کرد." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✅ Remote repository: $remoteUrl" -ForegroundColor Green
}

# انتخاب branch
Write-Host ""
$currentBranch = git branch --show-current
Write-Host "🌿 Branch فعلی: $currentBranch" -ForegroundColor Cyan
$pushBranch = Read-Host "نام branch برای push (Enter برای استفاده از '$currentBranch')"
if ([string]::IsNullOrWhiteSpace($pushBranch)) {
    $pushBranch = $currentBranch
}

# Push به GitHub
Write-Host ""
Write-Host "🚀 Push به GitHub..." -ForegroundColor Yellow
Write-Host "Branch: $pushBranch" -ForegroundColor Cyan
Write-Host ""

# سوال نهایی
$finalConfirm = Read-Host "آیا مطمئن هستید که می‌خواهید push کنید؟ (y/n)"
if ($finalConfirm -ne "y" -and $finalConfirm -ne "Y") {
    Write-Host "❌ Push لغو شد." -ForegroundColor Red
    exit 0
}

# اجرای push
git push -u origin $pushBranch

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  ✅ Push با موفقیت انجام شد!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "🔗 GitHub Actions workflow باید به صورت خودکار اجرا شود." -ForegroundColor Cyan
    Write-Host "📱 APK در بخش Actions > Artifacts قابل دانلود است." -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "❌ خطا در push! لطفاً مشکل را بررسی کنید." -ForegroundColor Red
    exit 1
}

