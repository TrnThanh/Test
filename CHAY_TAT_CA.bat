@echo off
chcp 65001 >nul
title [PTC1] KHOI DONG TOAN BO HE THONG (BACKEND + MOBILE + WEB)
cls
echo ==============================================================================
echo             KHOI DONG TOAN BO HE THONG PTC1 SPATIAL FOOD
echo ==============================================================================
echo.
echo [*] Buoc 1: Dang khoi dong Backend FastAPI tai cong 8001...
start "PTC1 Backend (Port 8001)" cmd /c "CHAY_SERVER.bat"

echo [*] Cho 3 giay de Backend khoi dong hoan tat...
timeout /t 3 /nobreak >nul

echo [*] Buoc 2: Dang khoi dong Web Admin Console tai http://localhost:5173 ...
start "PTC1 Web Admin (Port 5173)" cmd /c "CHAY_WEB.bat"

echo [*] Buoc 3: Dang khoi dong Flutter Mobile App tai http://localhost:3000 ...
start "PTC1 Mobile (Port 3000)" cmd /c "CHAY_MOBILE.bat"

echo.
echo [V] Da gui lenh khoi chay toan bo cac dich vu thanh cong!
echo.
