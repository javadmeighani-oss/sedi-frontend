# اسکریپت کامل: ساخت و نصب برنامه صدی روی موبایل

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ساخت و نصب برنامه صدی" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# بررسی دستگاه متصل
Write-Host "بررسی دستگاه متصل..." -ForegroundColor Yellow
$devices = adb devices
$phoneDevice = ($devices | Select-String "device" | Where-Object { $_ -notmatch "emulator" -and $_ -notmatch "List" } | Select-Object -First 1)

if (-not $phoneDevice) {
    Write-Host "❌ هیچ دستگاه متصل نیست!" -ForegroundColor Red
    Write-Host "لطفاً موبایل را با USB وصل کنید و USB Debugging را فعال کنید" -ForegroundColor Yellow
    exit
}

$deviceId = ($phoneDevice.ToString().Split("`t")[0]).Trim()
Write-Host "✅ دستگاه پیدا شد: $deviceId" -ForegroundColor Green
Write-Host ""

# مرحله 1: ساخت APK
Write-Host "مرحله 1: در حال ساخت APK..." -ForegroundColor Yellow
Write-Host "⚠️  اگر پیام تایید دانلود منابع را دیدید، 'y' را تایپ کنید" -ForegroundColor Yellow
Write-Host ""

flutter build apk --debug

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ خطا در ساخت APK" -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "✅ APK با موفقیت ساخته شد!" -ForegroundColor Green
Write-Host ""

# مرحله 2: نصب APK
$apkPath = "build\app\outputs\flutter-apk\app-debug.apk"

if (Test-Path $apkPath) {
    Write-Host "مرحله 2: در حال نصب روی موبایل..." -ForegroundColor Yellow
    Write-Host ""
    
    adb install -r $apkPath
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "  ✅ برنامه با موفقیت نصب شد!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "برنامه 'صدی' در موبایل شما آماده است!" -ForegroundColor Green
        Write-Host "می‌توانید آن را از لیست برنامه‌ها اجرا کنید." -ForegroundColor White
    } else {
        Write-Host ""
        Write-Host "❌ خطا در نصب. لطفاً دستی نصب کنید:" -ForegroundColor Red
        Write-Host "   فایل: $apkPath" -ForegroundColor White
    }
} else {
    Write-Host "❌ فایل APK پیدا نشد!" -ForegroundColor Red
}

