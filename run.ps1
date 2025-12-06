# اسکریپت اجرای خودکار Flutter
# این اسکریپت به صورت خودکار برنامه را اجرا می‌کند

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  در حال اجرای برنامه Sedi..." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# تنظیم متغیر محیطی برای دانلود خودکار
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.googleapis.com"

# بررسی وجود امولاتور
Write-Host "در حال بررسی دستگاه‌های متصل..." -ForegroundColor Yellow
flutter devices

Write-Host ""
Write-Host "در حال اجرای برنامه..." -ForegroundColor Green
Write-Host "اگر پیام تایید دانلود منابع را دیدید، 'y' را تایپ کنید" -ForegroundColor Yellow
Write-Host ""

# اجرای Flutter
flutter run -t lib/main.dart

