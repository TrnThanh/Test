@echo off
cd /d "%~dp0mobile"
title PTC1 Flutter Mobile (Port 3000)
echo ========================================================
echo   KHOI DONG FLUTTER MOBILE APP TAI http://localhost:3000
echo ========================================================
flutter run -d chrome --web-port=3000
pause
