@echo off
chcp 65001 >nul
title [DATABASE] Xuat Du Lieu Database PTC1 Sang File Du An
cls
echo ==============================================================================
echo             XUAT DU LIEU DATABASE PTC1 THANH TEP TRONG DU AN
echo ==============================================================================
echo.
cd /d "%~dp0"

:: Tim pg_dump.exe
set "PG_DUMP="
if exist "C:\Program Files\PostgreSQL\14\bin\pg_dump.exe" set "PG_DUMP=C:\Program Files\PostgreSQL\14\bin\pg_dump.exe"
if not defined PG_DUMP if exist "C:\Program Files\PostgreSQL\15\bin\pg_dump.exe" set "PG_DUMP=C:\Program Files\PostgreSQL\15\bin\pg_dump.exe"
if not defined PG_DUMP if exist "C:\Program Files\PostgreSQL\16\bin\pg_dump.exe" set "PG_DUMP=C:\Program Files\PostgreSQL\16\bin\pg_dump.exe"

if not defined PG_DUMP (
    echo [X] Chua tim thay PostgreSQL tren may: pg_dump.exe khong ton tai.
    echo [i] Vui long kiem tra PostgreSQL da duoc cai dat chua.
    echo.
    pause
    exit /b 1
)

set "OUT_FILE=scripts\database_dump.sql"
set PGPASSWORD=2005

echo [*] Tim thay PostgreSQL tai: "%PG_DUMP%"
echo [*] Dang trich xuat toan bo cac bang du lieu tu ptc1_db...
echo.

"%PG_DUMP%" -h localhost -p 5432 -U postgres -d ptc1_db --clean --if-exists --no-owner --no-privileges --column-inserts -t admins -t categories -t restaurants -t dishes -t favourite_dishes -t meal_types -t option_users -t users -t weather -t weather_categories -f "%OUT_FILE%"

if errorlevel 1 (
    echo.
    echo [X] Co loi xay ra khi trich xuat database!
    echo.
    pause
    exit /b 1
)

echo ==============================================================================
echo [OK] TRICH XUAT THANH CONG RA TEP: %OUT_FILE%
echo ==============================================================================
echo.
echo Tep %OUT_FILE% da san sang de commit va push len Git.
echo Nguoi khac khi clone/pull ve chi can chay 'CHAY_SERVER.bat' hoac 'CAI_DAT.bat' (he thong tu dong nạp seed).
echo.
pause
