@echo off
chcp 65001 >nul
title [DATABASE] Nap Du Lieu Mau Cho PTC1
cls
echo ==============================================================================
echo                 NAP DU LIEU DATABASE CHO DU AN PTC1
echo ==============================================================================
echo.
cd /d "%~dp0"

set "SQL_FILE=scripts\database_dump.sql"

if not exist "%SQL_FILE%" (
    echo [X] Khong tim thay file du lieu: %SQL_FILE%
    echo.
    pause
    exit /b 1
)

:: Tim psql.exe
set "PSQL_BIN="
if exist "C:\Program Files\PostgreSQL\14\bin\psql.exe" set "PSQL_BIN=C:\Program Files\PostgreSQL\14\bin\psql.exe"
if not defined PSQL_BIN if exist "C:\Program Files\PostgreSQL\15\bin\psql.exe" set "PSQL_BIN=C:\Program Files\PostgreSQL\15\bin\psql.exe"
if not defined PSQL_BIN if exist "C:\Program Files\PostgreSQL\16\bin\psql.exe" set "PSQL_BIN=C:\Program Files\PostgreSQL\16\bin\psql.exe"

if not defined PSQL_BIN (
    echo [X] Chua tim thay PostgreSQL tren may: psql.exe khong ton tai.
    echo [i] Vui long chay file 'CAI_DAT.bat' truoc de cai dat PostgreSQL 14 va PostGIS.
    echo.
    pause
    exit /b 1
)

set PGPASSWORD=2005

echo [*] Tim thay PostgreSQL tai: "%PSQL_BIN%"
echo [*] Dang kiem tra CSDL ptc1_db va PostGIS...

:: Tao database ptc1_db neu chua co
"%PSQL_BIN%" -h localhost -p 5432 -U postgres -d postgres -c "CREATE DATABASE ptc1_db;" >nul 2>&1

:: Kich hoat PostGIS
"%PSQL_BIN%" -h localhost -p 5432 -U postgres -d ptc1_db -c "CREATE EXTENSION IF NOT EXISTS postgis;" >nul 2>&1

echo [*] Dang nap toan bo du lieu tu %SQL_FILE% vao database ptc1_db...
echo.

"%PSQL_BIN%" -h localhost -p 5432 -U postgres -d ptc1_db -q -f "%SQL_FILE%"

if errorlevel 1 (
    echo.
    echo [X] Co loi xay ra khi nap du lieu. Vui long kiem tra PostgreSQL service da chay chua.
    echo.
    pause
    exit /b 1
)

echo.
echo ==============================================================================
echo [OK] DA NAP DU LIEU THANH CONG.
echo ==============================================================================
echo.
echo Thong ke du lieu trong ptc1_db:
"%PSQL_BIN%" -h localhost -p 5432 -U postgres -d ptc1_db -c "SELECT 'restaurants' AS bang, count(*) AS so_luong FROM restaurants UNION ALL SELECT 'dishes', count(*) FROM dishes UNION ALL SELECT 'categories', count(*) FROM categories UNION ALL SELECT 'users', count(*) FROM users UNION ALL SELECT 'weather', count(*) FROM weather;"
echo.
echo Ban da co day du du lieu quan an, mon an giong tren may nguon.
echo Ban co the khoi chay he thong bang cach click 'CHAY_SERVER.bat' hoac 'CHAY_TAT_CA.bat'.
echo.
pause
