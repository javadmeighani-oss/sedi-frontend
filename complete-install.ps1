# اسکریپت کامل: ساخت و نصب برنامه صدی روی موبایل

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ساخت و نصب برنامه صدی" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# بررسی دستگاه
Write-Host "بررسی دستگاه متصل..." -ForegroundColor Yellow
$devices = adb devices
$phoneDevice = ($devices | Select-String "device" | Where-Object { $_ -notmatch "emulator" -and $_ -notmatch "List" } | Select-Object -First 1)

if (-not $phoneDevice) {
    Write-Host "❌ هیچ دستگاه متصل نیست!" -ForegroundColor Red
    Write-Host "لطفاً موبایل را با USB وصل کنید" -ForegroundColor Yellow
    exit
}

$deviceId = ($phoneDevice.ToString().Split("`t")[0]).Trim()
Write-Host "✅ دستگاه پیدا شد: $deviceId" -ForegroundColor Green
Write-Host ""

# مرحله 1: ساخت APK
Write-Host "مرحله 1: در حال ساخت APK..." -ForegroundColor Yellow
Write-Host "⚠️  این مرحله ممکن است چند دقیقه طول بکشد" -ForegroundColor Yellow
Write-Host "⚠️  اگر پیام تایید دانلود منابع را دیدید، 'y' را تایپ کنید" -ForegroundColor Yellow
Write-Host ""

flutter build apk --debug

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "❌ خطا در ساخت APK" -ForegroundColor Red
    Write-Host "لطفاً دستور را دوباره اجرا کنید و وقتی پیام تایید را دیدید، 'y' را بزنید" -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "✅ APK با موفقیت ساخته شد!" -ForegroundColor Green
Write-Host ""

# مرحله 2: پیدا کردن و نصب APK
$apkPath = "build\app\outputs\flutter-apk\app-debug.apk"

if (Test-Path $apkPath) {
    Write-Host "مرحله 2: در حال نصب روی موبایل..." -ForegroundColor Yellow
    Write-Host ""
    
    # حذف نسخه قبلی (اگر وجود دارد)
    Write-Host "حذف نسخه قبلی (اگر وجود دارد)..." -ForegroundColor Gray
    adb uninstall com.sedi.app 2>$null | Out-Null
    
    # نصب APK جدید
    Write-Host "نصب APK جدید..." -ForegroundColor Gray
    adb install -r $apkPath
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ برنامه با موفقیت نصب شد!" -ForegroundColor Green
        Write-Host ""
        
        # اجرای برنامه
        Write-Host "در حال اجرای برنامه..." -ForegroundColor Yellow
        adb shell am start -n com.sedi.app/.MainActivity
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "  ✅ برنامه 'صدی' روی موبایل شما اجرا شد!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "برنامه در موبایل شما باز است و آماده تست است!" -ForegroundColor White
    } else {
        Write-Host ""
        Write-Host "❌ خطا در نصب" -ForegroundColor Red
        Write-Host "لطفاً دستی نصب کنید:" -ForegroundColor Yellow
        Write-Host "  فایل: $apkPath" -ForegroundColor White
    }
} else {
    Write-Host "❌ فایل APK پیدا نشد!" -ForegroundColor Red
    Write-Host "مسیر: $apkPath" -ForegroundColor Yellow
}

