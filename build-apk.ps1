# اسکریپت ساخت APK برای نصب مستقیم روی موبایل

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ساخت APK برنامه صدی" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "در حال ساخت APK..." -ForegroundColor Yellow
Write-Host "⚠️  اگر پیام تایید دانلود منابع را دیدید، 'y' را تایپ کنید" -ForegroundColor Yellow
Write-Host ""

# ساخت APK Debug
flutter build apk --debug

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ APK با موفقیت ساخته شد!" -ForegroundColor Green
    Write-Host ""
    Write-Host "مسیر فایل APK:" -ForegroundColor Cyan
    Write-Host "build\app\outputs\flutter-apk\app-debug.apk" -ForegroundColor White
    Write-Host ""
    Write-Host "برای نصب روی موبایل:" -ForegroundColor Yellow
    Write-Host "1. فایل APK را به موبایل منتقل کنید" -ForegroundColor White
    Write-Host "2. در موبایل روی فایل کلیک کنید و نصب کنید" -ForegroundColor White
    Write-Host "3. یا از دستور زیر استفاده کنید:" -ForegroundColor White
    Write-Host "   adb install build\app\outputs\flutter-apk\app-debug.apk" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "❌ خطا در ساخت APK" -ForegroundColor Red
}

