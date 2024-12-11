# Ensure script is running with administrative privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Relaunch the script with admin rights
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# Define the path to storage.json
$storagePath = Join-Path $env:APPDATA "Cursor\User\globalStorage\storage.json"

# Check if the storage file exists
if (-not (Test-Path $storagePath)) {
    Write-Host "Error: storage.json not found at $storagePath" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    Exit
}

# Generate random values
$uuid = [guid]::NewGuid().ToString()
$hex1 = -join ((48..57) + (97..102) | Get-Random -Count 64 | ForEach-Object {[char]$_})
$hex2 = -join ((48..57) + (97..102) | Get-Random -Count 64 | ForEach-Object {[char]$_})

# Remove read-only attribute if it exists
if ((Get-ItemProperty $storagePath).IsReadOnly) {
    Set-ItemProperty $storagePath -Name IsReadOnly -Value $false
}

# Create new JSON content
$jsonContent = @{
    'telemetry.macMachineId' = $hex1
    'telemetry.machineId' = $hex2
    'telemetry.devDeviceId' = $uuid
} | ConvertTo-Json

# Write the JSON content to file
$jsonContent | Set-Content -Path $storagePath

# Set read-only attribute
Set-ItemProperty $storagePath -Name IsReadOnly -Value $true

# Display the results
Write-Host "`nDone! File has been updated with new random values.`n" -ForegroundColor Green
Write-Host "New values:"
Write-Host "macMachineId: $hex1" -ForegroundColor Cyan
Write-Host "machineId: $hex2" -ForegroundColor Cyan
Write-Host "devDeviceId: $uuid" -ForegroundColor Cyan
Write-Host ""

Read-Host "Press Enter to exit" 