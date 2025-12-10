# دستورات Build و Push به GitHub
# این فایل را در PowerShell اجرا کنید: .\BUILD_AND_PUSH.ps1

# رفتن به پوشه frontend
cd "D:\Rimiya Design Studio\Sedi\software\Demo\frontend"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Push تغییرات طراحی جدید به GitHub" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# بررسی وضعیت
Write-Host "بررسی وضعیت Git..." -ForegroundColor Yellow
git status

Write-Host ""
Write-Host "اضافه کردن همه تغییرات..." -ForegroundColor Yellow
git add -A

Write-Host ""
Write-Host "ایجاد Commit..." -ForegroundColor Yellow
git commit -m "feat: بازطراحی کامل صفحه اصلی - لوگو با حلقه تپنده - چت باکس جدید - پشتیبانی چندزبانه - ورود اول"

Write-Host ""
Write-Host "Push به GitHub..." -ForegroundColor Yellow
git push origin main

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "✅ انجام شد!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "GitHub Actions به صورت خودکار build می‌کند" -ForegroundColor Cyan
Write-Host "برای مشاهده: https://github.com/javadmeighani-oss/sedi-frontend/actions" -ForegroundColor Cyan

