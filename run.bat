@echo off
REM اسکریپت اجرای خودکار Flutter برای Windows
REM این اسکریپت برنامه را اجرا می‌کند

echo ========================================
echo   در حال اجرای برنامه Sedi...
echo ========================================
echo.

REM تنظیم متغیر محیطی
set FLUTTER_STORAGE_BASE_URL=https://storage.googleapis.com

REM بررسی وجود امولاتور
echo در حال بررسی دستگاه‌های متصل...
flutter devices

echo.
echo در حال اجرای برنامه...
echo اگر پیام تایید دانلود منابع را دیدید، 'y' را تایپ کنید
echo.

REM اجرای Flutter
flutter run -t lib/main.dart

pause

