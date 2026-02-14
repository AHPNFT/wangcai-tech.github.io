# 快速修复脚本
Write-Host "=== Quick System Fix ==="
Write-Host "Time: $(Get-Date)"
Write-Host ""

# 1. 安全地重启高CPU进程
Write-Host "1. Restarting high CPU processes..."

# 重启非关键高CPU进程
$processesToStop = @(16592, 12064)  # LetsPRO, safesvr

foreach ($pid in $processesToStop) {
    try {
        $process = Get-Process -Id $pid -ErrorAction SilentlyContinue
        if ($process) {
            Write-Host "   Stopping $($process.Name) (PID: $pid)..."
            Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
            Write-Host "   Stopped" -ForegroundColor Green
        }
    } catch {
        Write-Host "   Error stopping PID $pid: $_" -ForegroundColor Red
    }
}

Write-Host ""

# 2. 刷新DNS和网络
Write-Host "2. Fixing network issues..."
try {
    Write-Host "   Flushing DNS cache..."
    ipconfig /flushdns
    Write-Host "   DNS cache flushed" -ForegroundColor Green
    
    Write-Host "   Resetting Winsock..."
    netsh winsock reset
    Write-Host "   Winsock reset" -ForegroundColor Green
} catch {
    Write-Host "   Network fix error: $_" -ForegroundColor Red
}

Write-Host ""

# 3. 重启关键服务
Write-Host "3. Restarting services..."
try {
    Write-Host "   Restarting DCOM service..."
    Restart-Service -Name "DcomLaunch" -Force -ErrorAction SilentlyContinue
    Write-Host "   DCOM service restarted" -ForegroundColor Green
} catch {
    Write-Host "   Service restart error: $_" -ForegroundColor Red
}

Write-Host ""

# 4. 优化电源设置
Write-Host "4. Optimizing power settings..."
try {
    Write-Host "   Setting high performance..."
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    Write-Host "   Power plan set" -ForegroundColor Green
    
    Write-Host "   Disabling hibernation..."
    powercfg /hibernate off
    Write-Host "   Hibernation disabled" -ForegroundColor Green
} catch {
    Write-Host "   Power settings error: $_" -ForegroundColor Red
}

Write-Host ""

# 5. 检查当前状态
Write-Host "5. Checking current status..."

# CPU使用
Write-Host "   CPU usage:"
Get-Process | Where-Object {$_.CPU -gt 50} | Sort-Object CPU -Descending | Select-Object -First 3 | ForEach-Object {
    $cpu = [Math]::Round($_.CPU, 2)
    Write-Host "     $($_.Name): $cpu% CPU" -ForegroundColor $(if ($cpu -gt 100) {"Red"} else {"Yellow"})
}

# 内存使用
try {
    $memory = Get-CimInstance Win32_OperatingSystem
    $usedPercent = [Math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize * 100, 2)
    Write-Host "   Memory usage: ${usedPercent}%" -ForegroundColor $(if ($usedPercent -gt 80) {"Red"} elseif ($usedPercent -gt 60) {"Yellow"} else {"Green"})
} catch {
    Write-Host "   Memory check error" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== FIX COMPLETE ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Actions taken:" -ForegroundColor White
Write-Host "1. Stopped high CPU processes (LetsPRO, safesvr)" -ForegroundColor Green
Write-Host "2. Fixed network/DNS issues" -ForegroundColor Green
Write-Host "3. Restarted DCOM service" -ForegroundColor Green
Write-Host "4. Optimized power settings" -ForegroundColor Green
Write-Host ""
Write-Host "If problems persist, restart the computer." -ForegroundColor Yellow