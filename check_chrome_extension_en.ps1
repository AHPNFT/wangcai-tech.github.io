# Check Chrome extension status
Write-Host "=== Chrome Extension Status Check ===" -ForegroundColor Cyan

# Check Chrome processes
Write-Host "`n1. Chrome Process Status:" -ForegroundColor Yellow
$chromeProcesses = Get-Process chrome -ErrorAction SilentlyContinue
if ($chromeProcesses) {
    Write-Host "   ✅ Chrome is running ($($chromeProcesses.Count) processes)" -ForegroundColor Green
    Write-Host "   Main process PID: $($chromeProcesses[0].Id)" -ForegroundColor White
} else {
    Write-Host "   ❌ Chrome is not running" -ForegroundColor Red
}

# Check OpenClaw gateway
Write-Host "`n2. OpenClaw Gateway Status:" -ForegroundColor Yellow
try {
    $gatewayStatus = openclaw status --json 2>$null
    if ($gatewayStatus) {
        Write-Host "   ✅ OpenClaw gateway is running" -ForegroundColor Green
    } else {
        Write-Host "   ❌ OpenClaw gateway is not running" -ForegroundColor Red
    }
} catch {
    Write-Host "   ⚠️ Cannot check OpenClaw status: $_" -ForegroundColor Yellow
}

# Check browser control port
Write-Host "`n3. Browser Control Port (18792):" -ForegroundColor Yellow
$portCheck = Test-NetConnection -ComputerName 127.0.0.1 -Port 18792 -InformationLevel Quiet
if ($portCheck) {
    Write-Host "   ✅ Port 18792 is listening" -ForegroundColor Green
} else {
    Write-Host "   ❌ Port 18792 is not listening" -ForegroundColor Red
}

# Manual steps needed
Write-Host "`n4. Chrome Extension Connection:" -ForegroundColor Yellow
Write-Host "   ⚠️ Manual check required:" -ForegroundColor Yellow
Write-Host "   1. Open Chrome browser" -ForegroundColor White
Write-Host "   2. Navigate to Gmail tab" -ForegroundColor White
Write-Host "   3. Click OpenClaw extension icon (top-right)" -ForegroundColor White
Write-Host "   4. Wait for extension to connect to tab" -ForegroundColor White

# Recommended actions
Write-Host "`n=== Recommended Actions ===" -ForegroundColor Cyan
Write-Host "1. Restart Chrome browser" -ForegroundColor White
Write-Host "2. Reopen Gmail tab" -ForegroundColor White
Write-Host "3. Click OpenClaw extension icon to connect" -ForegroundColor White
Write-Host "4. If still failing, restart OpenClaw gateway: openclaw gateway restart" -ForegroundColor White

Write-Host "`n=== Check Complete ===" -ForegroundColor Cyan