@echo off
chcp 65001 >nul
title [FLUTTER] PTC1 Mobile / Web App (Port 3000)
cls
echo ==============================================================================
echo                 KHOI DONG FLUTTER APP (PTC1 MOBILE)
echo ==============================================================================
echo.
cd /d "%~dp0mobile"

echo [*] Dang khoi chay Flutter tren Google Chrome tai http://localhost:3000 ...
flutter run -d chrome --web-port=3000

pause
