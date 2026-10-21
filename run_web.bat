@echo off
cd /d "%~dp0web"
title PTC1 Vue 3 Web App (Port 5173)
echo ========================================================
echo   KHOI DONG PTC1 VUE 3 WEB APP TAI http://localhost:5173
echo ========================================================
if not exist "node_modules" (
    call npm install
)
start "" "http://localhost:5173"
call npm run dev
pause
