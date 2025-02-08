# Ensure script is running with administrative privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# Helper functions
function New-MacMachineId {
    $template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    $result = ""
    $random = [Random]::new()
    
    foreach ($char in $template.ToCharArray()) {
        if ($char -eq 'x' -or $char -eq 'y') {
            $r = $random.Next(16)
            $v = if ($char -eq "x") { $r } else { ($r -band 0x3) -bor 0x8 }
            $result += $v.ToString("x")
        }
        else {
            $result += $char
        }
    }
    return $result
}

function New-RandomId {
    $uuid1 = [guid]::NewGuid().ToString("N")
    $uuid2 = [guid]::NewGuid().ToString("N")
    return $uuid1 + $uuid2
}

# Wait for Cursor process to exit
$cursorProcesses = Get-Process "cursor" -ErrorAction SilentlyContinue
if ($cursorProcesses) {
    Write-Host "Cursor is currently running. Please close Cursor to continue..."
    Write-Host "Waiting for Cursor process to exit..."
    
    while ($true) {
        $cursorProcesses = Get-Process "cursor" -ErrorAction SilentlyContinue
        if (-not $cursorProcesses) {
            Write-Host "Cursor has been closed, continuing..."
            break
        }
        Start-Sleep -Seconds 1
    }
}

# Backup MachineGuid
$backupDir = Join-Path $HOME "MachineGuid_Backups"
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir | Out-Null
}

$currentValue = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Cryptography" -Name MachineGuid
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = Join-Path $backupDir "MachineGuid_$timestamp.txt"
$counter = 0

while (Test-Path $backupFile) {
    $counter++
    $backupFile = Join-Path $backupDir "MachineGuid_${timestamp}_$counter.txt"
}

$currentValue.MachineGuid | Out-File $backupFile

# Update storage.json
$storageJsonPath = Join-Path $env:APPDATA "Cursor\User\globalStorage\storage.json"
$newMachineId = New-RandomId
$newMacMachineId = New-MacMachineId
$newDevDeviceId = [guid]::NewGuid().ToString()
$newSqmId = "{$([guid]::NewGuid().ToString().ToUpper())}"

if (Test-Path $storageJsonPath) {
    # Save original file attributes
    $originalAttributes = (Get-ItemProperty $storageJsonPath).Attributes
    
    # Remove read-only attribute
    Set-ItemProperty $storageJsonPath -Name IsReadOnly -Value $false
    
    # Update file content
    $jsonContent = Get-Content $storageJsonPath -Raw -Encoding UTF8
    $data = $jsonContent | ConvertFrom-Json
    
    # Check and update or add properties
    $properties = @{
        "telemetry.machineId"    = $newMachineId
        "telemetry.macMachineId" = $newMacMachineId
        "telemetry.devDeviceId"  = $newDevDeviceId
        "telemetry.sqmId"        = $newSqmId
    }

    foreach ($prop in $properties.Keys) {
        if (-not (Get-Member -InputObject $data -Name $prop -MemberType Properties)) {
            $data | Add-Member -NotePropertyName $prop -NotePropertyValue $properties[$prop]
        }
        else {
            $data.$prop = $properties[$prop]
        }
    }
    
    $newJson = $data | ConvertTo-Json -Depth 100
    
    # Save file using StreamWriter to ensure UTF-8 without BOM and LF line endings
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($storageJsonPath, $newJson.Replace("`r`n", "`n"), $utf8NoBom)
    
    # Restore original file attributes
    Set-ItemProperty $storageJsonPath -Name Attributes -Value $originalAttributes
}
else {
    Write-Host "Error: storage.json not found at $storageJsonPath" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    Exit
}

# Update registry MachineGuid
$newMachineGuid = [guid]::NewGuid().ToString()
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Cryptography" -Name "MachineGuid" -Value $newMachineGuid

# Display results
Write-Host "`nSuccessfully updated all IDs:" -ForegroundColor Green
Write-Host "Backup file created at: $backupFile"
Write-Host "New MachineGuid: $newMachineGuid"
Write-Host "New telemetry.machineId: $newMachineId"
Write-Host "New telemetry.macMachineId: $newMacMachineId"
Write-Host "New telemetry.devDeviceId: $newDevDeviceId"
Write-Host "New telemetry.sqmId: $newSqmId"

Read-Host "`nPress Enter to exit" 