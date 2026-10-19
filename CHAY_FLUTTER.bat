@echo off
chcp 65001 >nul
title [FLUTTER] PTC1 Mobile / Web App
cls
echo ==============================================================================
echo                 KHOI DONG FLUTTER APP (PTC1 MOBILE)
echo ==============================================================================
echo.
cd /d "%~dp0mobile"

echo [*] Dang khoi chay Flutter tren Google Chrome...
flutter run -d chrome

pause
