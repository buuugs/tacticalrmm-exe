$ErrorActionPreference = 'silentlycontinue'

# Assign the value random password to the password variable
$rustdesk_pw = "Tohaslomozezostaczmienione1"

# Get your config string from your Web portal and Fill Below
$rustdesk_cfg = "0nI9QTcw8EchR2QTpFN1RkZppHanNzci1WdpZnT0oUU0x0KlhnQrUVdykmWjNlI6ISeltmIsICbw5Cc19mcnNTbus2clRGdzVncv8iOzBHd0hmI6ISawFmIsICbw5Cc19mcnNTbus2clRGdzVnciojI5FGblJnIsICbw5Cc19mcnNTbus2clRGdzVnciojI0N3boJye"

################################## Please Do Not Edit Below This Line #########################################

# Run as administrator and stays in the current directory
if (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$pwd'; & '$PSCommandPath';`"";
        Exit;
    }
}

$Downloadlink = "https://rustdesk.m3group.pl/download/m3group.exe"

if (!(Test-Path C:\Temp)) {
    New-Item -ItemType Directory -Force -Path C:\Temp | Out-Null
}

Set-Location C:\Temp

Invoke-WebRequest $Downloadlink -Outfile "m3group.exe"

Start-Process .\m3group.exe --silent-install
Start-Sleep -seconds 20

$newPath = "$env:ProgramFiles\Pomoc zdalna M3 Group\Pomoc zdalna M3 Group.exe --service"
$ServiceName = 'Rustdesk'
$arrService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if ($arrService -eq $null) {
    Set-Location $env:ProgramFiles
    Set-Location 'Pomoc zdalna M3 Group'
    Start-Process ".\Pomoc zdalna M3 Group.exe" --install-service
    Start-Sleep -seconds 10
    if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
        sc.exe config $ServiceName binPath= $newPath > $null 2>&1
    }
    else {
        sc.exe create $ServiceName binPath= $newPath start= auto > $null 2>&1
    }
    $arrService = Get-Service -Name $ServiceName
}

while ($arrService.Status -ne 'Running') {
    Start-Service $ServiceName
    Start-Sleep -seconds 5
    $arrService.Refresh()
}

# Konfiguracja RustDesk
Set-Location $env:ProgramFiles
Set-Location 'Pomoc zdalna M3 Group'

& ".\Pomoc zdalna M3 Group.exe" --get-id | Write-Output -OutVariable rustdesk_id
& ".\Pomoc zdalna M3 Group.exe" --config $rustdesk_cfg
& ".\Pomoc zdalna M3 Group.exe" --password $rustdesk_pw

# Uruchomienie jako aplikacja GUI dla aktywnego użytkownika
Start-Process ".\Pomoc zdalna M3 Group.exe" --run

