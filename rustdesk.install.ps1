$ErrorActionPreference = 'SilentlyContinue'

# Ustaw ścieżkę logu
$LogFile = "C:\Temp\rustdesk_install.log"
if (!(Test-Path C:\Temp)) {
    New-Item -ItemType Directory -Force -Path C:\Temp | Out-Null
}

# Funkcja pomocnicza do logowania
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] $Message"
    Write-Host $entry
    Add-Content -Path $LogFile -Value $entry
}

# Konfiguracja RustDesk
$rustdesk_cfg = "0nI9QTcw8EchR2QTpFN1RkZppHanNzci1WdpZnT0oUU0x0KlhnQrUVdykmWjNlI6ISeltmIsICbw5Cc19mcnNTbus2clRGdzVncv8iOzBHd0hmI6ISawFmIsICbw5Cc19mcnNTbus2clRGdzVnciojI5FGblJnIsICbw5Cc19mcnNTbus2clRGdzVnciojI0N3boJye"

$ServiceName = 'Rustdesk'
$ProgramFolder = "$env:ProgramFiles\Pomoc zdalna M3 Group"
$ExePath = Join-Path $ProgramFolder "Pomoc zdalna M3 Group.exe"

if ((Test-Path $ExePath) -and (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue)) {
    Write-Log "RustDesk (Pomoc zdalna M3 Group) is already installed. Skipping installation."
} else {
    $Downloadlink = "https://rustdesk.m3group.pl/download/m3group.exe"

    Set-Location C:\Temp
    Write-Log "Pobieranie instalatora RustDesk..."
    Invoke-WebRequest $Downloadlink -Outfile "m3group.exe" -ErrorAction SilentlyContinue
    Write-Log "Instalacja RustDesk..."
    Start-Process .\m3group.exe --silent-install
    Start-Sleep -Seconds 20

    $newPath = "`"$env:ProgramFiles\Pomoc zdalna M3 Group\Pomoc zdalna M3 Group.exe`" --service"
    $arrService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

    if ($arrService -eq $null) {
        Set-Location $ProgramFolder
        Write-Log "Rejestracja usługi RustDesk..."
        Start-Process ".\Pomoc zdalna M3 Group.exe" --install-service
        Start-Sleep -Seconds 10

        if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
            Write-Log "Aktualizacja ścieżki usługi..."
            sc.exe config $ServiceName binPath= $newPath > $null 2>&1
        } else {
            Write-Log "Tworzenie nowej usługi RustDesk..."
            sc.exe create $ServiceName binPath= $newPath start= auto > $null 2>&1
        }

        $arrService = Get-Service -Name $ServiceName
    }

    while ($arrService.Status -ne 'Running') {
        Write-Log "Uruchamianie usługi RustDesk..."
        Start-Service $ServiceName
        Start-Sleep -Seconds 5
        $arrService.Refresh()
    }
    Write-Log "Usługa RustDesk uruchomiona."
}

if (Test-Path $ExePath) {
    Set-Location $ProgramFolder

    Write-Log "Pobieranie ID RustDesk..."
    $rustdesk_id = & ".\Pomoc zdalna M3 Group.exe" --get-id 2>&1
    Write-Log "ID RustDesk: $rustdesk_id"

    Write-Log "Ustawianie konfiguracji RustDesk..."
    & ".\Pomoc zdalna M3 Group.exe" --config $rustdesk_cfg

    Write-Log "Uruchamianie GUI RustDesk..."
    Start-Process ".\Pomoc zdalna M3 Group.exe" --run
}

