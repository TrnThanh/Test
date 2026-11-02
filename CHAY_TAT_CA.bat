@echo off
chcp 65001 >nul
title [PTC1] KHOI DONG TOAN BO HE THONG (SERVER + WEB + MOBILE)
cls
echo ==============================================================================
echo             KHOI DONG TOAN BO HE THONG PTC1 (SERVER + WEB + MOBILE)
echo ==============================================================================
echo.
cd /d "%~dp0"

:: 1. KHOI DONG BACKEND FASTAPI (Port 8001)
echo [*] Buoc 1: Dang khoi dong Backend FastAPI tai http://localhost:8001 ...
if exist "%~dp0.venv\Scripts\python.exe" (
    start "PTC1 Backend FastAPI (Port 8001)" cmd /k "chcp 65001 >nul & cd /d "%~dp0" & title [PTC1] Backend FastAPI (Port 8001) & echo [*] Dang chay Backend tai http://localhost:8001 ... & "%~dp0.venv\Scripts\python.exe" -m uvicorn server.app.main:app --reload --host 0.0.0.0 --port 8001"
) else (
    start "PTC1 Backend FastAPI (Port 8001)" cmd /k "chcp 65001 >nul & cd /d "%~dp0" & title [PTC1] Backend FastAPI (Port 8001) & echo [*] Dang chay Backend tai http://localhost:8001 ... & python -m uvicorn server.app.main:app --reload --host 0.0.0.0 --port 8001"
)

:: Mo Health Check tren trinh duyet (Swagger docs da tat, test bang Postman)
start "" "http://localhost:8001/"

echo [*] Cho 3 giay de Backend on dinh he thong...
timeout /t 3 /nobreak >nul

:: 2. KHOI DONG WEB FRONTEND VUE 3 (Port 5174)
echo [*] Buoc 2: Dang khoi dong Web Client (Vue 3 + Vite) tai http://localhost:5174 ...
if not exist "%~dp0web\node_modules" (
    echo [*] Thu vien node_modules chua ton tai, dang tien hanh npm install...
    cd /d "%~dp0web" && call npm install && cd /d "%~dp0"
)
start "PTC1 Web Client (Port 5174)" cmd /k "chcp 65001 >nul & cd /d "%~dp0web" & title [PTC1] Web Client (Port 5174) & echo [*] Dang chay Vite Dev Server tai http://localhost:5174 ... & npm run dev"

:: Mo Web tren trinh duyet
start "" "http://localhost:5174"

:: 3. KHOI DONG FLUTTER MOBILE (Port 3000)
echo [*] Buoc 3: Dang khoi dong Flutter Mobile App tai http://localhost:3000 ...
start "PTC1 Mobile App (Port 3000)" cmd /k "chcp 65001 >nul & cd /d "%~dp0mobile" & title [PTC1] Mobile Client (Port 3000) & echo [*] Dang khoi chay Flutter tren Google Chrome tai http://localhost:3000 ... & flutter run -d chrome --web-port=3000"

echo.
echo ==============================================================================
echo [V] DA KHOI CHAY TOAN BO HE THONG THANH CONG!
echo     - Backend FastAPI:  http://localhost:8001/ (Health Check - Postman base: /api/v1)
echo     - Web Client:       http://localhost:5174
echo     - Mobile Client:    http://localhost:3000
echo.
echo     Moi dich vu dang chay doc lap trong 1 cua so console rieng biet.
echo     Nhan phim bat ky de dong cua so nay (cac dich vu van tiep tuc chay).
echo ==============================================================================
echo.
pause
