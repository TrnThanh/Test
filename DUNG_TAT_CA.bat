@echo off
chcp 65001 >nul
title [PTC1] DUNG TOAN BO HE THONG
cls
echo ==============================================================================
echo                 DUNG TOAN BO HE THONG PTC1 (SERVER + WEB + MOBILE)
echo ==============================================================================
echo.

echo [*] Dang tim va dung cac tien trinh Backend (Port 8001)...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8001 ^| findstr LISTENING') do (
    taskkill /F /PID %%a >nul 2>&1
)

echo [*] Dang tim va dung cac tien trinh Web Client (Port 5174)...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :5174 ^| findstr LISTENING') do (
    taskkill /F /PID %%a >nul 2>&1
)

echo [*] Dang tim va dung cac tien trinh Flutter Mobile (Port 3000)...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :3000 ^| findstr LISTENING') do (
    taskkill /F /PID %%a >nul 2>&1
)

echo [*] Dang don dep cac tien trinh uvicorn, node dev, dart...
taskkill /F /IM dart.exe >nul 2>&1

echo.
echo ==============================================================================
echo [V] DA DUNG TOAN BO HE THONG THANH CONG!
echo ==============================================================================
echo.
timeout /t 2 >nul
