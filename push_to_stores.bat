@echo off
title Focus Oasis - Push to GitHub and Trigger Linux Release
color 0A
echo ================================================================
echo   Focus Oasis - Push to GitHub and Trigger Linux Release
echo ================================================================
echo.
echo [1/2] Pushing main branch...
git push -u origin main
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Push failed. Please authenticate with GitHub when prompted.
    echo.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [2/2] Pushing release tag v1.0.0...
git push origin v1.0.0
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Failed to push tag v1.0.0.
    echo.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ================================================================
echo   SUCCESS! Pushed to GitHub.
echo   GitHub Actions is now automatically building:
echo   1. Ubuntu Snap Store (Canonical)
echo   2. Flathub Flatpak Manifest
echo   3. Debian Package (.deb)
echo   4. Portable AppImage
echo ================================================================
echo.
pause
