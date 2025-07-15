$ErrorActionPreference = 'SilentlyContinue'

# Get your config string from your Web portal
$rustdesk_cfg = "0nI9QTcw8EchR2QTpFN1RkZppHanNzci1WdpZnT0oUU0x0KlhnQrUVdykmWjNlI6ISeltmIsICbw5Cc19mcnNTbus2clRGdzVncv8iOzBHd0hmI6ISawFmIsICbw5Cc19mcnNTbus2clRGdzVnciojI5FGblJnIsICbw5Cc19mcnNTbus2clRGdzVnciojI0N3boJye"

################################## Do Not Edit Below #########################################

$ServiceName = 'Rustdesk'
$ProgramFolder = "$env:ProgramFiles\Pomoc zdalna M3 Group"
$ExePath = Join-Path $ProgramFolder "Pomoc zdalna M3 Group.exe"

# If RustDesk is already installed, skip
if (Test-Path $ExePath -and (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue)) {
    Write-Host "RustDesk (Pomoc zdalna M3 Group) is already installed. Skipping installation."
} else {
    # Download and install
    $Downloadlink = "https://rustdesk.m3group.pl/download/m3group.exe"

    if (!(Test-Path C:\Temp)) {
        New-Item -ItemType Directory -Force -Path C:\Temp | Out-Null
    }

    Set-Location C:\Temp
    Invoke-WebRequest $Downloadlink -Outfile "m3group.exe"

    Write-Host "Installing RustDesk..."
    Start-Process .\m3group.exe --silent-install
    Start-Sleep -Seconds 20

    $newPath = "`"$env:ProgramFiles\Pomoc zdalna M3 Group\Pomoc zdalna M3 Group.exe`" --service"
    $arrService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

    if ($arrService -eq $null) {
        Set-Location $env:ProgramFiles
        Set-Location 'Pomoc zdalna M3 Group'
        Start-Process ".\Pomoc zdalna M3 Group.exe" --install-service
        Start-Sleep -Seconds 10

        if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
            sc.exe config $ServiceName binPath= $newPath > $null 2>&1
        } else {
            sc.exe create $ServiceName binPath= $newPath start= auto > $null 2>&1
        }

        $arrService = Get-Service -Name $ServiceName
    }

    while ($arrService.Status -ne 'Running') {
        Start-Service $ServiceName
        Start-Sleep -Seconds 5
        $arrService.Refresh()
    }
}

# RustDesk Configuration
if (Test-Path $ExePath) {
    Set-Location $ProgramFolder

    & ".\Pomoc zdalna M3 Group.exe" --get-id | Write-Output -OutVariable rustdesk_id
    & ".\Pomoc zdalna M3 Group.exe" --config $rustdesk_cfg

    # Launch GUI in interactive session
    Start-Process ".\Pomoc zdalna M3 Group.exe" --run
}
