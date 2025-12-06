# اسکریپت اجرای برنامه صدی روی موبایل اندرویدی

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  اجرای برنامه صدی روی موبایل" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# بررسی دستگاه‌های متصل
Write-Host "بررسی دستگاه‌های متصل..." -ForegroundColor Yellow
$devices = adb devices
Write-Host $devices
Write-Host ""

# پیدا کردن دستگاه فیزیکی
$phoneDevice = ($devices | Select-String "device" | Where-Object { $_ -notmatch "emulator" } | Select-Object -First 1).ToString().Split("`t")[0]

if ($phoneDevice) {
    Write-Host "دستگاه پیدا شد: $phoneDevice" -ForegroundColor Green
    Write-Host ""
    Write-Host "در حال اجرای برنامه..." -ForegroundColor Green
    Write-Host "⚠️  اگر پیام تایید دانلود منابع را دیدید، 'y' را تایپ کنید" -ForegroundColor Yellow
    Write-Host ""
    
    # اجرای برنامه روی دستگاه فیزیکی
    flutter run -d $phoneDevice -t lib/main.dart
} else {
    Write-Host "❌ هیچ دستگاه فیزیکی متصل نیست!" -ForegroundColor Red
    Write-Host ""
    Write-Host "لطفاً:" -ForegroundColor Yellow
    Write-Host "1. USB Debugging را در تنظیمات Developer Options فعال کنید" -ForegroundColor White
    Write-Host "2. موبایل را با USB به کامپیوتر وصل کنید" -ForegroundColor White
    Write-Host "3. مجوز USB Debugging را در موبایل تایید کنید" -ForegroundColor White
}

