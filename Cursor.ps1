# Generate new UUIDs and convert them to lowercase
Write-Host "Step 1: Generating new identifiers..." -ForegroundColor Green
$new_machine_id = [guid]::NewGuid().ToString().ToLower()
$new_dev_device_id = [guid]::NewGuid().ToString().ToLower()
$new_mac_machine_id = -join ((1..32) | ForEach-Object { "{0:x}" -f (Get-Random -Max 16) })
Write-Host "Generated new IDs successfully" -ForegroundColor Gray

# Define file paths
Write-Host "`nStep 2: Setting up file paths..." -ForegroundColor Green
$machine_id_path = "$env:APPDATA\Cursor\machineid"
$storage_json_path = "$env:APPDATA\Cursor\User\globalStorage\storage.json"
Write-Host "Path Found"

# Backup original files
Write-Host "`nStep 3: Creating backups..." -ForegroundColor Green
Copy-Item $machine_id_path "$machine_id_path.backup" -ErrorAction SilentlyContinue
Copy-Item $storage_json_path "$storage_json_path.backup" -ErrorAction SilentlyContinue
Write-Host "Backup files created (if original files existed)" -ForegroundColor Gray

# Update the machineid file
Write-Host "`nStep 4: Updating machine ID..." -ForegroundColor Green
$new_machine_id | Out-File -FilePath $machine_id_path -Encoding UTF8 -NoNewline
Write-Host "Machine ID updated successfully" -ForegroundColor Gray

# Read and update the storage.json file
Write-Host "`nStep 5: Updating storage.json..." -ForegroundColor Green
$content = Get-Content $storage_json_path -Raw | ConvertFrom-Json
$content.'telemetry.devDeviceId' = $new_dev_device_id
$content.'telemetry.macMachineId' = $new_mac_machine_id
$content | ConvertTo-Json -Depth 100 | Out-File $storage_json_path -Encoding UTF8
Write-Host "Storage.json updated successfully" -ForegroundColor Gray

Write-Host "`nAll steps completed successfully!" -ForegroundColor Green
