@echo off
REM اسکریپت اجرای خودکار Flutter

echo ========================================
echo   در حال اجرای برنامه Sedi...
echo ========================================
echo.

REM تنظیم متغیر محیطی
set FLUTTER_STORAGE_BASE_URL=https://storage.googleapis.com

echo در حال بررسی دستگاه‌های متصل...
flutter devices

echo.
echo در حال اجرای برنامه...
echo.
echo اگر پیام تایید دانلود منابع را دیدید، 'y' را تایپ کنید
echo.

REM اجرای Flutter
flutter run -t lib/main.dart

pause

