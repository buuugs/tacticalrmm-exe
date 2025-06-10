@echo off
setlocal enabledelayedexpansion

:: === CONFIG ===
set "SERVICE_NAME=tacticalrmm"
set "EXE_DIR=C:\Program Files\TacticalAgent"
set "EXE_NAME=tacticalrmm.exe"
set "EXE_PATH=%EXE_DIR%\%EXE_NAME%"
set "EXPECTED_BINARY_PATH=\"%EXE_PATH%\" -m svc"
set "DOWNLOAD_URL=https://github.com/buuugs/tacticalrmm-exe/releases/download/sda/tacticalrmm.exe"
set "DISPLAY_NAME=TacticalRMM Agent Service"

:: === FUNCTION: delay n seconds ===
:delay
    ping 127.0.0.1 -n %~1 >nul
    goto :eof

:: === 1. Sprawdź, czy usługa istnieje ===
sc qc "%SERVICE_NAME%" >nul 2>&1
if %errorlevel% EQU 0 (
    :: 1.a. Pobierz BINARY_PATH_NAME
    for /f "tokens=1,* delims=:" %%A in ('sc qc "%SERVICE_NAME%" ^| findstr /I "BINARY_PATH_NAME"') do (
        set "BINPATH=%%B"
    )
    :: usuń wiodące spacje
    set "BINPATH=!BINPATH:~1!"
    :: 1.b. Sprawdź, czy ścieżka zgadza się z oczekiwaną
    if /I "!BINPATH!"=="%EXPECTED_BINARY_PATH%" (
        :: 1.c. Sprawdź, czy usługa jest uruchomiona
        sc query "%SERVICE_NAME%" | findstr /I "STATE.*RUNNING" >nul 2>&1
        if %errorlevel% EQU 0 (
            echo Usługa "%SERVICE_NAME%" istnieje, ma poprawną ścieżkę i jest uruchomiona. Kończę.
            goto :EOF
        )
    )
    echo Usługa "%SERVICE_NAME%" jest nieprawidłowa lub zatrzymana. Będę reinstalować...
    :: 1.d. Usuń starą usługę
    sc delete "%SERVICE_NAME%" >nul 2>&1
    call :delay 5
) else (
    echo Usługa "%SERVICE_NAME%" nie istnieje. Instaluję...
)

:: === 2. Pobierz plik i zarejestruj usługę ===
:: 2.a. Przejdź do katalogu
if not exist "%EXE_DIR%" md "%EXE_DIR%"
cd /d "%EXE_DIR%"

:: 2.b. Pobierz nowy plik
echo Pobieram %EXE_NAME%...
PowerShell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%EXE_NAME%'" 
call :delay 3

:: 2.c. Utwórz usługę
echo Tworzę usługę "%SERVICE_NAME%"...
sc create "%SERVICE_NAME%" binPath= "\"%EXE_PATH%\" -m svc" start= auto DisplayName= "%DISPLAY_NAME%" error= ignore
call :delay 2

:: 2.d. Uruchom usługę
echo Uruchamiam usługę...
net start "%SERVICE_NAME%"

echo Gotowe.
endlocal
exit /b
