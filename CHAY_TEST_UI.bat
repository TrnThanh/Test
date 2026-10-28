@echo off
chcp 65001 >nul
title [TEST] PTC1 E2E UI Workflows & Multi-tier Monitor
cls
echo ==============================================================================
echo             KIEM THU GIAO DIEN E2E DA TANG (PTC1 UI FLOWS)
echo        (UI Test + Soi loi Console + Soi loi Server + Chup anh man hinh)
echo ==============================================================================
echo.
cd /d "%~dp0"

if not exist ".venv\Scripts\python.exe" (
    echo [X] Khong tim thay Python trong thu muc .venv!
    echo [i] Vui long chay CAI_DAT.bat truoc de khoi tao moi truong.
    echo.
    pause
    exit /b 1
)

echo [*] Dang khoi dong bo kieu thu tu dong Playwright...
echo.

".venv\Scripts\python.exe" -m e2e_flows.runner %*

echo.
echo ==============================================================================
echo [*] Kiem thu hoan tat! Anh chup man hinh luu tai: e2e_flows\screenshots\
echo [*] Bao cao chi tiet luu tai: e2e_flows\reports\summary.md
echo ==============================================================================
echo.
pause
