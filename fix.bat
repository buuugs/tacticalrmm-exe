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

rem ——— Czy usługa istnieje? ——————————————————————
sc query "%SERVICE_NAME%" >nul 2>&1
if %errorlevel%==0 (
    echo  Usługa istnieje – sprawdzam poprawność konfiguracji...

    rem Pobierz pełną binarną ścieżkę
    for /f "tokens=2*" %%a in ('sc qc "%SERVICE_NAME%" ^| findstr /i "BINARY_PATH_NAME"') do set "BIN_PATH=%%b"
    set "BIN_PATH=!BIN_PATH:~1!"  rem usuń wiodącą spację

    if /i "!BIN_PATH!"=="\"%EXE_PATH%\" -m svc" (
rem ——— Ścieżka jest OK – sprawdź stan (Running / Stopped) —
for /f "tokens=3" %%a in ('sc query "%SERVICE_NAME%" ^| findstr /i "STATE"') do set "STATE=%%a"

if /i "!STATE!"=="RUNNING" (
    echo  Usługa działa i ma poprawną ścieżkę. Nic do zrobienia.
    goto :EOF
)

if "!STATE!"=="4" (
    echo  Usługa działa (kod 4) i ma poprawną ścieżkę. Nic do zrobienia.
    goto :EOF
)

echo  Usługa ma poprawną ścieżkę, lecz jest w stanie !STATE!.  Próbuję ją uruchomić...
net start "%SERVICE_NAME%" && (
    echo  Usługa uruchomiona.
    goto :EOF
)
echo  Nie udało się uruchomić – reinstalacja.

        )
    ) else (
        echo  Ścieżka binarna NIEZGODNA:
        echo    !BIN_PATH!
        echo     Oczekiwano: "%EXE_PATH% -m svc"
        echo    Przeinstaluję usługę.
    )
) else (
    echo  Usługa nie istnieje – przechodzę do instalacji.
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
    echo  Blad: plik nie zostal pobrany.  Koncze.
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
if %errorlevel%==0 (echo  Usluga uruchomiona pomyslnie.) else (echo  Nie udalo sie uruchomic!)

echo.
echo ==== [TacticalRMM] Gotowe ====
endlocal
exit /b
