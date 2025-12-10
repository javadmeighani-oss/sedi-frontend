# دستورات کامل برای Push به GitHub
# این فایل را در PowerShell اجرا کنید: .\PUSH_TO_GITHUB.ps1

# رفتن به پوشه frontend
cd "D:\Rimiya Design Studio\Sedi\software\Demo\frontend"

# بررسی وضعیت
Write-Host "بررسی وضعیت Git..." -ForegroundColor Yellow
git status

# اضافه کردن همه تغییرات
Write-Host "اضافه کردن تغییرات..." -ForegroundColor Yellow
git add -A

# Commit
Write-Host "ایجاد Commit..." -ForegroundColor Yellow
git commit -m "fix: اصلاح settings.gradle برای سازگاری با Flutter 3.24.5"

# Push
Write-Host "Push به GitHub..." -ForegroundColor Yellow
git push origin main

Write-Host "✅ انجام شد!" -ForegroundColor Green

