@echo off
rem === TacticalRMM Agent - manualny update binarki ===================
rem === v4: fix syntax error, copy zamiast move =====================

setlocal enabledelayedexpansion

set "SERVICE_NAME=tacticalrmm"
set "INSTALL_DIR=C:\Program Files\TacticalAgent"
set "EXE_PATH=%INSTALL_DIR%\tacticalrmm.exe"
set "BACKUP_PATH=%INSTALL_DIR%\tacticalrmm.exe.bak"
set "DOWNLOAD_URL=https://github.com/buuugs/tacticalrmm-exe/releases/download/sda/tacticalrmm.exe"
set "STAGE_DIR=C:\ProgramData\TacticalRMM"
set "TEMP_PATH=%STAGE_DIR%\tacticalrmm_new.exe"

echo.
echo ==== [TacticalRMM] Manualny update agenta v4 ====
echo.

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo BLAD: Wymagane uprawnienia administratora.
    pause
    exit /b 1
)

sc query "%SERVICE_NAME%" >nul 2>&1
if %errorlevel% neq 0 (
    echo BLAD: Usluga "%SERVICE_NAME%" nie istnieje.
    pause
    exit /b 1
)

if not exist "%EXE_PATH%" (
    echo BLAD: Brak pliku %EXE_PATH%
    pause
    exit /b 1
)

if not exist "%STAGE_DIR%" mkdir "%STAGE_DIR%" 2>nul

echo Aktualna wersja:
"%EXE_PATH%" -m about 2>nul | findstr /i "version"
echo.

if exist "%TEMP_PATH%" del /F /Q "%TEMP_PATH%" >nul 2>&1

echo Pobieram do %STAGE_DIR%...
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%TEMP_PATH%' -UseBasicParsing; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 }"

if not exist "%TEMP_PATH%" (
    echo BLAD: Nie pobrano pliku.
    pause
    exit /b 1
)

for %%A in ("%TEMP_PATH%") do set "FILE_SIZE=%%~zA"
if !FILE_SIZE! LSS 1000000 (
    echo BLAD: Pobrany plik za maly - !FILE_SIZE! bajtow.
    del /F /Q "%TEMP_PATH%" >nul 2>&1
    pause
    exit /b 1
)
echo Pobrano: !FILE_SIZE! bajtow

echo.
echo Zatrzymuje usluge...
net stop "%SERVICE_NAME%" >nul 2>&1
sc stop "%SERVICE_NAME%" >nul 2>&1
ping 127.0.0.1 -n 5 >nul

taskkill /F /IM tacticalrmm.exe >nul 2>&1
taskkill /F /IM checkrunner.exe >nul 2>&1
ping 127.0.0.1 -n 3 >nul

tasklist /FI "IMAGENAME eq tacticalrmm.exe" 2>nul | findstr /i "tacticalrmm.exe" >nul
if !errorlevel! equ 0 (
    echo Ostrzezenie: tacticalrmm.exe nadal dziala, czekam dluzej...
    ping 127.0.0.1 -n 10 >nul
    taskkill /F /IM tacticalrmm.exe >nul 2>&1
    ping 127.0.0.1 -n 3 >nul
)

echo Backup starej binarki...
if exist "%BACKUP_PATH%" del /F /Q "%BACKUP_PATH%" >nul 2>&1
copy /Y "%EXE_PATH%" "%BACKUP_PATH%" >nul
if %errorlevel% neq 0 (
    echo BLAD: Nie udalo sie zrobic backupu.
    net start "%SERVICE_NAME%" >nul 2>&1
    pause
    exit /b 1
)

echo Usuwam stara binarke...
del /F /Q "%EXE_PATH%" >nul 2>&1
if exist "%EXE_PATH%" (
    echo Plik zablokowany, czekam i probuje ponownie...
    ping 127.0.0.1 -n 5 >nul
    del /F /Q "%EXE_PATH%" >nul 2>&1
)

if exist "%EXE_PATH%" (
    echo BLAD: Nie mozna usunac starej binarki - plik zablokowany.
    echo Przywracam i koncze.
    net start "%SERVICE_NAME%" >nul 2>&1
    pause
    exit /b 1
)

echo Kopiuje nowa binarke...
copy /Y /B "%TEMP_PATH%" "%EXE_PATH%" >nul 2>&1
set "COPY_RC=!errorlevel!"

if not exist "%EXE_PATH%" (
    echo.
    echo ============================================================
    echo BLAD: Nie udalo sie skopiowac nowej binarki
    echo errorlevel: !COPY_RC!
    echo ============================================================
    echo.
    echo Diagnostyka:
    echo.
    echo Plik docelowy istnieje:
    if exist "%EXE_PATH%" (echo   TAK) else (echo   NIE)
    echo.
    echo Plik zrodlowy istnieje:
    if exist "%TEMP_PATH%" (echo   TAK) else (echo   NIE - AV go usunal podczas kopiowania)
    echo.
    echo Uprawnienia folderu docelowego:
    icacls "%INSTALL_DIR%" 2>nul
    echo.
    echo Przywracam backup...
    copy /Y "%BACKUP_PATH%" "%EXE_PATH%" >nul
    net start "%SERVICE_NAME%" >nul 2>&1
    pause
    exit /b 1
)

del /F /Q "%TEMP_PATH%" >nul 2>&1

echo Uruchamiam usluge...
net start "%SERVICE_NAME%"
if %errorlevel% neq 0 (
    echo BLAD: Usluga nie wstala, przywracam backup...
    del /F /Q "%EXE_PATH%" >nul 2>&1
    copy /Y "%BACKUP_PATH%" "%EXE_PATH%" >nul
    net start "%SERVICE_NAME%"
    pause
    exit /b 1
)

ping 127.0.0.1 -n 4 >nul

echo.
echo ==== Update OK ====
echo Nowa wersja:
"%EXE_PATH%" -m about 2>nul | findstr /i "version"
echo.
echo Backup: %BACKUP_PATH%
echo.

endlocal
exit /b 0
