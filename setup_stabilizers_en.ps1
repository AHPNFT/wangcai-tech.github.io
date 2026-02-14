# Setup Chrome Extension Stabilizers - English Version

Write-Host "=== Chrome Extension Stabilizer Setup ===" -ForegroundColor Cyan
Write-Host "Version: 1.0" -ForegroundColor White
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
Write-Host "`nSetting up stabilizers..." -ForegroundColor Yellow

# 1. Create simple stabilizer script
Write-Host "`n1. Creating stabilizer script..." -ForegroundColor Yellow

$stabilizerScript = @'
# Chrome Extension Stabilizer
param([int]$CheckInterval = 300)

Write-Host "=== Chrome Extension Stabilizer ===" -ForegroundColor Cyan
Write-Host "Check interval: $CheckInterval seconds" -ForegroundColor White
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow

while ($true) {
    $time = Get-Date -Format "HH:mm:ss"
    $chrome = Get-Process chrome -ErrorAction SilentlyContinue
    
    if ($chrome) {
        Write-Host "[$time] Chrome: Running ($($chrome.Count) processes)" -ForegroundColor Green
        
        # Check OpenClaw
        try {
            $status = openclaw status --json 2>$null
            if ($status) {
                Write-Host "  OpenClaw: Running" -ForegroundColor Green
            } else {
                Write-Host "  OpenClaw: Not running" -ForegroundColor Red
            }
        } catch {
            Write-Host "  OpenClaw: Check failed" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[$time] Chrome: Not running" -ForegroundColor Red
    }
    
    Start-Sleep -Seconds $CheckInterval
}
'@

Set-Content -Path "C:\Users\Administrator\.openclaw\workspace\chrome_stabilizer.ps1" -Value $stabilizerScript -Encoding UTF8
Write-Host "  Created: chrome_stabilizer.ps1" -ForegroundColor Green

# 2. Create connection checker
Write-Host "`n2. Creating connection checker..." -ForegroundColor Yellow

$checkerScript = @'
# Quick Connection Checker
Write-Host "=== Chrome Extension Connection Check ===" -ForegroundColor Cyan

# Check Chrome
$chrome = Get-Process chrome -ErrorAction SilentlyContinue
if ($chrome) { 
    Write-Host "Chrome: Running ($($chrome.Count) processes)" -ForegroundColor Green 
} else { 
    Write-Host "Chrome: Not running" -ForegroundColor Red 
}

# Check OpenClaw
try {
    $status = openclaw status --json 2>$null
    if ($status) { 
        Write-Host "OpenClaw: Running" -ForegroundColor Green 
    } else { 
        Write-Host "OpenClaw: Not running" -ForegroundColor Red 
    }
} catch { 
    Write-Host "OpenClaw: Check failed" -ForegroundColor Yellow 
}

# Check port
$port = Test-NetConnection -ComputerName 127.0.0.1 -Port 18792 -InformationLevel Quiet
if ($port) { 
    Write-Host "Port 18792: Listening" -ForegroundColor Green 
} else { 
    Write-Host "Port 18792: Not listening" -ForegroundColor Red 
}

Write-Host "`n=== Check Complete ===" -ForegroundColor Cyan
Write-Host "`nManual steps needed:" -ForegroundColor Yellow
Write-Host "1. Open Chrome browser" -ForegroundColor White
Write-Host "2. Go to Gmail tab" -ForegroundColor White
Write-Host "3. Click OpenClaw extension icon (top-right)" -ForegroundColor White
Write-Host "4. Wait for connection" -ForegroundColor White
'@

Set-Content -Path "C:\Users\Administrator\.openclaw\workspace\check_connection.ps1" -Value $checkerScript -Encoding UTF8
Write-Host "  Created: check_connection.ps1" -ForegroundColor Green

# 3. Create startup task
Write-Host "`n3. Creating startup task..." -ForegroundColor Yellow

$taskName = "OpenClaw Chrome Stabilizer"
$scriptPath = "C:\Users\Administrator\.openclaw\workspace\chrome_stabilizer.ps1"

try {
    # Remove existing task
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    
    # Create new task
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -Force
    Write-Host "  Scheduled task created: $taskName" -ForegroundColor Green
} catch {
    Write-Host "  Failed to create task: $_" -ForegroundColor Yellow
}

# 4. Create desktop shortcuts
Write-Host "`n4. Creating desktop shortcuts..." -ForegroundColor Yellow

$desktop = [Environment]::GetFolderPath("Desktop")

# Shortcut 1: Stabilizer
try {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$desktop\Chrome Stabilizer.lnk")
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
    $Shortcut.WorkingDirectory = "C:\Users\Administrator\.openclaw\workspace"
    $Shortcut.WindowStyle = 7
    $Shortcut.IconLocation = "C:\Windows\System32\SHELL32.dll,71"
    $Shortcut.Save()
    Write-Host "  Created: Chrome Stabilizer.lnk" -ForegroundColor Green
} catch {
    Write-Host "  Failed to create shortcut" -ForegroundColor Yellow
}

# Shortcut 2: Connection Checker
try {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$desktop\Check Connection.lnk")
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -NoExit -File `"C:\Users\Administrator\.openclaw\workspace\check_connection.ps1`""
    $Shortcut.WorkingDirectory = "C:\Users\Administrator\.openclaw\workspace"
    $Shortcut.WindowStyle = 1
    $Shortcut.IconLocation = "C:\Windows\System32\SHELL32.dll,22"
    $Shortcut.Save()
    Write-Host "  Created: Check Connection.lnk" -ForegroundColor Green
} catch {
    Write-Host "  Failed to create shortcut" -ForegroundColor Yellow
}

# 5. Start stabilizer now
Write-Host "`n5. Starting stabilizer now..." -ForegroundColor Yellow

try {
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`"" -WindowStyle Hidden
    Write-Host "  Stabilizer started" -ForegroundColor Green
} catch {
    Write-Host "  Failed to start stabilizer: $_" -ForegroundColor Yellow
}

# 6. Run connection check
Write-Host "`n6. Running connection check..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

try {
    powershell -ExecutionPolicy Bypass -File "C:\Users\Administrator\.openclaw\workspace\check_connection.ps1"
} catch {
    Write-Host "  Connection check failed" -ForegroundColor Red
}

Write-Host "`n=== Setup Complete ===" -ForegroundColor Cyan
Write-Host "`nStabilizers configured:" -ForegroundColor White
Write-Host "1. Stabilizer script (runs every 5 minutes)" -ForegroundColor Green
Write-Host "2. Startup task (auto-start on boot)" -ForegroundColor Green
Write-Host "3. Desktop shortcuts (2 shortcuts)" -ForegroundColor Green
Write-Host "4. Connection checker" -ForegroundColor Green
Write-Host "5. Stabilizer running now" -ForegroundColor Green

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Open Chrome browser" -ForegroundColor White
Write-Host "2. Go to Gmail tab" -ForegroundColor White
Write-Host "3. Click OpenClaw extension icon (top-right)" -ForegroundColor White
Write-Host "4. Wait for connection" -ForegroundColor White

Write-Host "`nMonitoring:" -ForegroundColor Yellow
Write-Host "• Double-click 'Check Connection' desktop shortcut" -ForegroundColor White
Write-Host "• Check Task Manager for powershell processes" -ForegroundColor White

Write-Host "`nMANUAL CONNECTION REQUIRED NOW!" -ForegroundColor Red -BackgroundColor White