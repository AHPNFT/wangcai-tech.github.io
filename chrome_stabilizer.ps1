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
