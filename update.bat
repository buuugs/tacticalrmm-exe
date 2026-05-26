@echo off
rem === TacticalRMM Agent — manualny update binarki ===================
rem === v2: pobiera do folderu wykluczonego z AV (WithSecure friendly)
rem === Zachowuje konfiguracje (rejestr HKLM\SOFTWARE\TacticalRMM) ====

setlocal enabledelayedexpansion

rem ——— Konfiguracja ————————————————————————————
set "SERVICE_NAME=tacticalrmm"
set "INSTALL_DIR=C:\Program Files\TacticalAgent"
set "EXE_PATH=%INSTALL_DIR%\tacticalrmm.exe"
set "BACKUP_PATH=%INSTALL_DIR%\tacticalrmm.exe.bak"
set "DOWNLOAD_URL=https://github.com/buuugs/tacticalrmm-exe/releases/download/sda/tacticalrmm.exe"

rem ——— Folder na pobrany plik (musi byc w AV exclusions!) ————
set "STAGE_DIR=C:\ProgramData\TacticalRMM"
set "TEMP_PATH=%STAGE_DIR%\tacticalrmm_new.exe"

echo.
echo ==== [TacticalRMM] Manualny update agenta ====
echo.

rem ——— Sprawdz uprawnienia administratora —————————————
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo BLAD: Skrypt wymaga uprawnien administratora.
    echo Uruchom CMD jako administrator i sprobuj ponownie.
    pause
    exit /b 1
)

rem ——— Sprawdz czy agent w ogole istnieje —————————————
sc query "%SERVICE_NAME%" >nul 2>&1
if %errorlevel% neq 0 (
    echo BLAD: Usluga "%SERVICE_NAME%" nie istnieje.
    echo Najpierw zainstaluj agenta przez reinstall.bat.
    pause
    exit /b 1
)

if not exist "%EXE_PATH%" (
    echo BLAD: Brak pliku %EXE_PATH%
    echo Najpierw zainstaluj agenta przez reinstall.bat.
    pause
    exit /b 1
)

rem ——— Upewnij sie ze stage dir istnieje —————————————
if not exist "%STAGE_DIR%" (
    echo Tworze katalog stage: %STAGE_DIR%
    mkdir "%STAGE_DIR%" 2>nul
)

rem ——— Pokaz aktualna wersje —————————————————————
echo Aktualna wersja agenta:
"%EXE_PATH%" -m about 2>nul | findstr /i "version"
echo.

rem ——— Wyczysc stary stage jesli zostal ———————————————
if exist "%TEMP_PATH%" (
    echo Usuwam stary plik z poprzedniej proby...
    del /F /Q "%TEMP_PATH%" >nul 2>&1
)

rem ——— Pobierz nowa binarke DO FOLDERU WYKLUCZONEGO Z AV ————
echo Pobieram nowa wersje EXE do %STAGE_DIR%...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "try { Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%TEMP_PATH%' -UseBasicParsing; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 }"

if not exist "%TEMP_PATH%" (
    echo BLAD: Nie udalo sie pobrac pliku.
    echo Sprawdz czy folder %STAGE_DIR% jest w wykluczeniach AV.
    pause
    exit /b 1
)

rem ——— Sanity check rozmiaru ———————————————————————
for %%A in ("%TEMP_PATH%") do set "FILE_SIZE=%%~zA"
if !FILE_SIZE! LSS 1000000 (
    echo BLAD: Pobrany plik ma tylko !FILE_SIZE! bajtow - za maly.
    echo Prawdopodobnie 404 albo AV obcial plik.
    del /F /Q "%TEMP_PATH%" >nul 2>&1
    pause
    exit /b 1
)
echo Pobrano: !FILE_SIZE! bajtow (OK)

rem ——— Zatrzymaj usluge —————————————————————————
echo.
echo Zatrzymuje usluge "%SERVICE_NAME%"...
net stop "%SERVICE_NAME%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Ostrzezenie: net stop nie zadzialal, probuje sc stop...
    sc stop "%SERVICE_NAME%" >nul 2>&1
)

rem Daj 4 sekundy na faktyczne zwolnienie pliku
ping 127.0.0.1 -n 5 >nul

rem ——— Zatrzymaj rowniez proces checkrunner / agent helper (jesli zyje) —
taskkill /F /IM tacticalrmm.exe >nul 2>&1
ping 127.0.0.1 -n 2 >nul

rem ——— Backup starej binarki ——————————————————————
echo Robie backup starej binarki...
if exist "%BACKUP_PATH%" del /F /Q "%BACKUP_PATH%" >nul 2>&1
move /Y "%EXE_PATH%" "%BACKUP_PATH%" >nul 2>&1
if %errorlevel% neq 0 (
    echo BLAD: Nie mozna zarchiwizowac starej binarki.
    echo Plik moze byc nadal zablokowany. Sprobuj jeszcze raz za chwile.
    pause
    exit /b 1
)

rem ——— Podmien binarke ——————————————————————————
echo Instaluje nowa binarke (z %STAGE_DIR% do %INSTALL_DIR%)...
move /Y "%TEMP_PATH%" "%EXE_PATH%" >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ============================================================
    echo BLAD: Nie udalo sie przeniesc pliku do %INSTALL_DIR%
    echo ============================================================
    echo.
    echo Mozliwe przyczyny:
    echo  - AV nadal blokuje (sprawdz wykluczenia)
    echo  - Brak uprawnien do %INSTALL_DIR%
    echo  - Plik jest jeszcze zablokowany przez proces
    echo.
    echo Przywracam backup...
    move /Y "%BACKUP_PATH%" "%EXE_PATH%" >nul
    net start "%SERVICE_NAME%" >nul 2>&1
    pause
    exit /b 1
)

rem ——— Uruchom usluge ——————————————————————————
echo Uruchamiam usluge...
net start "%SERVICE_NAME%"
if %errorlevel% neq 0 (
    echo BLAD: Usluga nie wstala z nowa binarka. Przywracam backup...
    move /Y "%BACKUP_PATH%" "%EXE_PATH%" >nul
    net start "%SERVICE_NAME%"
    pause
    exit /b 1
)

rem ——— Daj agentowi czas na start ———————————————————
ping 127.0.0.1 -n 4 >nul

echo.
echo ==== [TacticalRMM] Update zakonczony pomyslnie ====
echo Nowa wersja agenta:
"%EXE_PATH%" -m about 2>nul | findstr /i "version"
echo.
echo Backup starej binarki: %BACKUP_PATH%
echo (mozesz usunac jesli nowa wersja dziala stabilnie)
echo.

endlocal
exit /b 0
