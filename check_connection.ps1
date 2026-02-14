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
