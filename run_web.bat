@echo off
cd /d "%~dp0web"
title PTC1 Web Admin Console (Port 5173)
echo ========================================================
echo   KHOI DONG WEB ADMIN CONSOLE TAI http://localhost:5173
echo ========================================================
npm run dev
pause
