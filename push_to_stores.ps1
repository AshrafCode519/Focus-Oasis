[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  🌿 واحة التركيز (Focus Oasis) - رفع التحديثات وبناء نسخ لينكس" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/2] جارٍ رفع الفرع الرئيسي (main)..." -ForegroundColor Yellow
git push -u origin main
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "❌ فشل الرفع إلى الفرع الرئيسي. يرجى تسجيل الدخول عند ظهور النافذة." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "[2/2] جارٍ رفع علامة الإصدار (v1.0.0)..." -ForegroundColor Yellow
git push origin v1.0.0
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "❌ فشل رفع علامة الإصدار v1.0.0." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "  🎉 تم الرفع بنجاح!" -ForegroundColor Green
Write-Host "  بدأ سير عمل GitHub Actions الآن بناء كافة نسخ ومتاجر لينكس:" -ForegroundColor Cyan
Write-Host "  1. متجر أوبونتو (Canonical Snap Store)" -ForegroundColor White
Write-Host "  2. متجر فلات هاب العالمي (Flathub)" -ForegroundColor White
Write-Host "  3. حزم دبيان وأوبونتو (.deb)" -ForegroundColor White
Write-Host "  4. حزم AppImage المحمولة" -ForegroundColor White
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
