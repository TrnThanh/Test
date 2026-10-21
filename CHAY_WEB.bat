@echo off
chcp 65001 >nul
title [WEB] PTC1 Vue 3 Frontend (Port 5173)
cls
echo ==============================================================================
echo                 KHOI DONG WEB CLIENT PTC1 (VUE 3 + VITE)
echo ==============================================================================
echo.
cd /d "%~dp0web"

if not exist "node_modules" (
    echo [*] Thu vien node_modules chua ton tai, dang tien hanh npm install...
    call npm install
    echo.
)

echo [*] Dang khoi chay Vite Dev Server tai http://localhost:5173 ...
echo [*] Dang tu dong mo Web Frontend tren trinh duyet...
echo.

start "" "http://localhost:5173"

call npm run dev

pause
