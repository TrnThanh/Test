@echo off
chcp 65001 >nul
title [PTC1] KHOI DONG TOAN BO HE THONG (BACKEND + FLUTTER)
cls
echo ==============================================================================
echo             KHOI DONG TOAN BO HE THONG PTC1 SPATIAL FOOD
echo ==============================================================================
echo.
echo [*] Buoc 1: Dang khoi dong Backend FastAPI tai cong 8001...
start "PTC1 Backend (Port 8001)" cmd /c "CHAY_SERVER.bat"

echo [*] Cho 3 giay de Backend khoi dong hoan tat...
timeout /t 3 /nobreak >nul

echo [*] Buoc 2: Dang khoi dong Flutter Web App tai http://localhost:3000 ...
start "PTC1 Flutter (Port 3000)" cmd /c "CHAY_FLUTTER.bat"

echo.
echo [V] Da gui lenh khoi chay ca Backend (8001) va Flutter Web (3000) thanh cong!
echo.
