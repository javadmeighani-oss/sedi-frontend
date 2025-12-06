# اسکریپت اجرای خودکار Flutter
# این اسکریپت برنامه را اجرا می‌کند

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  در حال اجرای برنامه Sedi..." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# تنظیم متغیر محیطی
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.googleapis.com"

Write-Host "در حال بررسی دستگاه‌های متصل..." -ForegroundColor Yellow
flutter devices

Write-Host ""
Write-Host "در حال اجرای برنامه..." -ForegroundColor Green
Write-Host ""
Write-Host "⚠️  اگر پیام زیر را دیدید:" -ForegroundColor Yellow
Write-Host "   'Flutter assets will be downloaded...'" -ForegroundColor Yellow
Write-Host "   فقط 'y' را تایپ کنید و Enter بزنید" -ForegroundColor Yellow
Write-Host ""

# اجرای flutter run
flutter run -t lib/main.dart

