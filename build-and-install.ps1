# اسکریپت کامل: ساخت و نصب خودکار برنامه صدی
# این اسکریپت از Gradle مستقیماً استفاده می‌کند

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
    exit
}

$deviceId = ($phoneDevice.ToString().Split("`t")[0]).Trim()
Write-Host "✅ دستگاه پیدا شد: $deviceId" -ForegroundColor Green
Write-Host ""

# استفاده از Gradle برای build (بدون نیاز به Flutter CLI)
Write-Host "مرحله 1: در حال build با Gradle..." -ForegroundColor Yellow
Write-Host ""

# رفتن به دایرکتوری Android
Push-Location android

# Build با Gradle
.\gradlew.bat assembleDebug

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ خطا در build" -ForegroundColor Red
    Pop-Location
    exit
}

Pop-Location

Write-Host ""
Write-Host "✅ Build با موفقیت انجام شد!" -ForegroundColor Green
Write-Host ""

# پیدا کردن فایل APK
$apkPath = "build\app\outputs\flutter-apk\app-debug.apk"

if (-not (Test-Path $apkPath)) {
    # اگر در مسیر Flutter نبود، مسیر Gradle را چک کن
    $apkPath = "android\app\build\outputs\apk\debug\app-debug.apk"
}

if (Test-Path $apkPath) {
    Write-Host "مرحله 2: در حال نصب روی موبایل..." -ForegroundColor Yellow
    Write-Host ""
    
    # حذف نسخه قبلی (اگر وجود دارد)
    adb uninstall com.sedi.app 2>$null
    
    # نصب APK جدید
    adb install -r $apkPath
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "  ✅ برنامه با موفقیت نصب شد!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "در حال اجرای برنامه..." -ForegroundColor Yellow
        
        # اجرای برنامه
        adb shell am start -n com.sedi.app/.MainActivity
        
        Write-Host ""
        Write-Host "✅ برنامه 'صدی' روی موبایل شما اجرا شد!" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "❌ خطا در نصب" -ForegroundColor Red
    }
} else {
    Write-Host "❌ فایل APK پیدا نشد!" -ForegroundColor Red
    Write-Host "مسیرهای بررسی شده:" -ForegroundColor Yellow
    Write-Host "  - build\app\outputs\flutter-apk\app-debug.apk" -ForegroundColor White
    Write-Host "  - android\app\build\outputs\apk\debug\app-debug.apk" -ForegroundColor White
}

