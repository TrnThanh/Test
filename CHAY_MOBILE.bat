@echo off
chcp 65001 >nul
title [MOBILE] PTC1 Flutter App (Port 3000)
cls
echo ==============================================================================
echo                 KHOI DONG FLUTTER MOBILE APP (PTC1)
echo ==============================================================================
echo.
cd /d "%~dp0mobile"

echo [*] Dang khoi chay Flutter tren Google Chrome tai http://localhost:3000 ...
flutter run -d chrome --web-port=3000

pause
