@echo off
chcp 65001 >nul
title Focus Oasis - Push to GitHub and Trigger Linux Release
color 0A
echo ================================================================
echo   🌿 واحة التركيز - رفع التحديثات وبناء نسخ ومتاجر لينكس
echo ================================================================
echo.
echo [1/2] جارٍ رفع الفرع الرئيسي (main)...
git push -u origin main
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ فشل الرفع. يرجى تسجيل الدخول إلى GitHub عند ظهور النافذة المنبثقة.
    echo.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [2/2] جارٍ رفع علامة الإصدار (v1.0.0)...
git push origin v1.0.0

echo.
echo ================================================================
echo   🎉 تم الرفع بنجاح!
echo   بدأ GitHub Actions الآن بناء كافة نسخ ومتاجر لينكس آلياً:
echo   1. متجر أوبونتو (Canonical Snap Store)
echo   2. متجر فلات هاب العالمي (Flathub)
echo   3. حزم دبيان وأوبونتو (.deb)
echo   4. حزم AppImage المحمولة
echo ================================================================
echo.
pause
