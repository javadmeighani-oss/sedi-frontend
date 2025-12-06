# اسکریپت اجرای برنامه صدی روی امولاتور Android

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  اجرای برنامه صدی روی Android" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# بررسی امولاتور
Write-Host "بررسی امولاتور..." -ForegroundColor Yellow
$devices = adb devices
Write-Host $devices

Write-Host ""
Write-Host "در حال اجرای برنامه..." -ForegroundColor Green
Write-Host ""
Write-Host "⚠️  اگر پیام تایید دانلود منابع را دیدید:" -ForegroundColor Yellow
Write-Host "   فقط 'y' را تایپ کنید و Enter بزنید" -ForegroundColor Yellow
Write-Host ""

# اجرای برنامه
flutter run -d emulator-5554 -t lib/main.dart

