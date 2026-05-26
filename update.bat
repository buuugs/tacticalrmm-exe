@echo off
rem === TacticalRMM Agent — manualny update binarki ===================
rem === Zachowuje konfiguracje (rejestr HKLM\SOFTWARE\TacticalRMM) ====

setlocal enabledelayedexpansion

rem ——— Konfiguracja ————————————————————————————
set "SERVICE_NAME=tacticalrmm"
set "INSTALL_DIR=C:\Program Files\TacticalAgent"
set "EXE_PATH=%INSTALL_DIR%\tacticalrmm.exe"
set "BACKUP_PATH=%INSTALL_DIR%\tacticalrmm.exe.bak"
set "DOWNLOAD_URL=https://github.com/buuugs/tacticalrmm-exe/releases/download/sda/tacticalrmm.exe"
set "TEMP_PATH=%TEMP%\tacticalrmm_new.exe"

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

rem ——— Pokaz aktualna wersje —————————————————————
echo Aktualna wersja agenta:
"%EXE_PATH%" -m about 2>nul | findstr /i "version"
echo.

rem ——— Pobierz nowa binarke do tempa —————————————————
echo Pobieram nowa wersje EXE...
del "%TEMP_PATH%" >nul 2>&1

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "try { Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%TEMP_PATH%' -UseBasicParsing; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 }"

if not exist "%TEMP_PATH%" (
    echo BLAD: Nie udalo sie pobrac pliku.
    pause
    exit /b 1
)

rem ——— Sprawdz rozmiar pobranego pliku (sanity check) ————
for %%A in ("%TEMP_PATH%") do set "FILE_SIZE=%%~zA"
if !FILE_SIZE! LSS 1000000 (
    echo BLAD: Pobrany plik ma tylko !FILE_SIZE! bajtow - za maly, prawdopodobnie blad pobierania.
    del "%TEMP_PATH%" >nul 2>&1
    pause
    exit /b 1
)
echo Pobrano: !FILE_SIZE! bajtow

rem ——— Zatrzymaj usluge —————————————————————————
echo.
echo Zatrzymuje usluge "%SERVICE_NAME%"...
net stop "%SERVICE_NAME%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Ostrzezenie: nie udalo sie zatrzymac przez net stop, probuje sc stop...
    sc stop "%SERVICE_NAME%" >nul 2>&1
)

rem Daj czas Windowsowi na faktyczne zwolnienie pliku
ping 127.0.0.1 -n 4 >nul

rem ——— Zrob backup starej binarki ——————————————————
echo Robie backup starej binarki...
del "%BACKUP_PATH%" >nul 2>&1
move /Y "%EXE_PATH%" "%BACKUP_PATH%" >nul
if %errorlevel% neq 0 (
    echo BLAD: Nie mozna zarchiwizowac starej binarki. Prawdopodobnie usluga sie nie zatrzymala.
    echo Probuje wymusic zatrzymanie...
    taskkill /F /IM tacticalrmm.exe >nul 2>&1
    ping 127.0.0.1 -n 3 >nul
    move /Y "%EXE_PATH%" "%BACKUP_PATH%" >nul
    if !errorlevel! neq 0 (
        echo BLAD krytyczny: nie udalo sie podmienic pliku.
        echo Spróbuj uruchomic skrypt ponownie albo zrestartuj komputer.
        pause
        exit /b 1
    )
)

rem ——— Podmien binarke ——————————————————————————
echo Instaluje nowa binarke...
move /Y "%TEMP_PATH%" "%EXE_PATH%" >nul
if %errorlevel% neq 0 (
    echo BLAD: Nie mozna skopiowac nowej binarki. Przywracam backup.
    move /Y "%BACKUP_PATH%" "%EXE_PATH%" >nul
    net start "%SERVICE_NAME%" >nul 2>&1
    pause
    exit /b 1
)

rem ——— Uruchom usluge ——————————————————————————
echo Uruchamiam usluge...
net start "%SERVICE_NAME%"
if %errorlevel% neq 0 (
    echo BLAD: Nie udalo sie uruchomic uslugi z nowa binarka. Przywracam backup.
    move /Y "%BACKUP_PATH%" "%EXE_PATH%" >nul
    net start "%SERVICE_NAME%"
    pause
    exit /b 1
)

rem ——— Daj agentowi sekunde na start i pokaz nowa wersje ————
ping 127.0.0.1 -n 3 >nul

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
