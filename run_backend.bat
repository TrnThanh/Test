@echo off
cd /d "%~dp0"
title PTC1 Backend Server (Port 8001)
echo ========================================================
echo   KHOI DONG BACKEND FASTAPI PTC1 TAI http://127.0.0.1:8001
echo   Tai lieu API Swagger Docs: http://127.0.0.1:8001/docs
echo ========================================================
.\.venv\Scripts\python.exe -m uvicorn server.app.main:app --host 0.0.0.0 --port 8001 --reload
pause
