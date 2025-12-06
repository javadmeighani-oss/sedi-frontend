# اسکریپت اجرای Flutter با راهنمایی برای تایید
# این اسکریپت به شما کمک می‌کند تا برنامه را اجرا کنید

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  راهنمای اجرای برنامه Sedi" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# تنظیم متغیر محیطی
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.googleapis.com"

Write-Host "مرحله 1: بررسی دستگاه‌های متصل..." -ForegroundColor Yellow
flutter devices

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  مرحله 2: اجرای برنامه" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  توجه: اگر پیام زیر را دیدید:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Flutter assets will be downloaded from" -ForegroundColor White
Write-Host "   https://storage.googleapis.com." -ForegroundColor White
Write-Host "   Make sure you trust this source!" -ForegroundColor White
Write-Host ""
Write-Host "   → فقط حرف 'y' را تایپ کنید و Enter بزنید" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# اجرای Flutter
flutter run -t lib/main.dart

