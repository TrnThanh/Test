@echo off
chcp 65001 >nul
title [SERVER] PTC1 FastAPI Backend (Port 8001)
cls
echo ==============================================================================
echo                 KHOI DONG BACKEND SERVER PTC1 (FASTAPI)
echo ==============================================================================
echo.
cd /d "%~dp0"

if not exist ".venv\Scripts\python.exe" (
    echo [X] Chua tim thay moi truong ao .venv!
    echo [i] Vui long chay file 'CAI_DAT.bat' truoc de cai dat he thong.
    echo.
    pause
    exit /b 1
)

echo [*] Dang khoi chay FastAPI Server tai http://localhost:8001 ...
echo [*] Dang tu dong mo Swagger UI tren trinh duyet...
echo.

start "" "http://localhost:8001/docs"

".venv\Scripts\uvicorn.exe" server.app.main:app --reload --host 0.0.0.0 --port 8001

pause
