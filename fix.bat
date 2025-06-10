@echo off
rem === TacticalRMM Agent installer/updater ==========================
setlocal enabledelayedexpansion

rem ——— Konfiguracja ————————————————————————————
set "SERVICE_NAME=tacticalrmm"
set "INSTALL_DIR=C:\Program Files\TacticalAgent"
set "EXE_PATH=%INSTALL_DIR%\tacticalrmm.exe"
set "DOWNLOAD_URL=https://github.com/buuugs/tacticalrmm-exe/releases/download/sda/tacticalrmm.exe"

echo.
echo ==== [TacticalRMM] Sprawdzanie stanu uslugi "%SERVICE_NAME%" ====

rem ——— Czy usluga istnieje? ——————————————————————
sc query "%SERVICE_NAME%" >nul 2>&1
if %errorlevel%==0 (
    echo  Usluga istnieje – sprawdzam poprawnosc konfiguracji...

    rem Pobierz pelna binarna sciezke
    for /f "tokens=2*" %%a in ('sc qc "%SERVICE_NAME%" ^| findstr /i "BINARY_PATH_NAME"') do set "BIN_PATH=%%b"
    set "BIN_PATH=!BIN_PATH:~1!"  rem usun wiodaca spacje

    if /i "!BIN_PATH!"=="\"%EXE_PATH%\" -m svc" (
        rem –—— Ścieżka jest OK – sprawdź stan (Running / Stopped) —
        for /f "tokens=3" %%a in ('sc query "%SERVICE_NAME%" ^| findstr /i "STATE"') do set "STATE=%%a"
        if /i "!STATE!"=="RUNNING" (
            echo  Usluga dziala i ma poprawna sciezke. Nic do zrobienia.
            goto :EOF
        ) else (
            echo  Usluga ma poprawna sciezke, lecz jest w stanie !STATE!.  Probuje ja uruchomic...
            net start "%SERVICE_NAME%" && echo ✓ Usluga uruchomiona. && goto :EOF
            echo ✗ Nie udalo sie uruchomic – reinstalacja.
        )
    ) else (
        echo ✗ Sciezka binarna NIEZGODNA:
        echo    !BIN_PATH!
        echo    ↳ Oczekiwano: "%EXE_PATH% -m svc"
        echo    Przeinstaluje usluge.
    )
) else (
    echo  Usluga nie istnieje – przechodze do instalacji.
)

rem ——— Instalacja / reinstalacja ————————————————————
echo.
echo ==== [TacticalRMM] Instalacja / aktualizacja agenta ====

echo  Tworze katalog instalacyjny "%INSTALL_DIR%"...
mkdir "%INSTALL_DIR%" 2>nul

echo  Pobieram EXE:
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%EXE_PATH%'"
if not exist "%EXE_PATH%" (
    echo ✗ Blad: plik nie zostal pobrany.  Koncze.
    goto :EOF
)
rem t
echo  Usuwam stara usluge (jesli byla)...
sc delete "%SERVICE_NAME%" >nul 2>&1
ping 127.0.0.1 -n 3 >nul

echo  Rejestruje nowa usluge...
sc create "%SERVICE_NAME%" ^
    binPath= "\"%EXE_PATH%\" -m svc" ^
    start= auto ^
    DisplayName= "TacticalRMM Agent Service" ^
    error= ignore

echo  Uruchamiam usluge...
net start "%SERVICE_NAME%"
if %errorlevel%==0 (echo ✓ Usluga uruchomiona pomyslnie.) else (echo ✗ Nie udalo sie uruchomic!)

echo.
echo ==== [TacticalRMM] Gotowe ====
endlocal
exit /b
