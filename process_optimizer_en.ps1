# Process Optimizer Script - Safe optimization of system processes
Write-Host "Starting process optimization..." -ForegroundColor Cyan

# 1. Show current high CPU processes
Write-Host "`nCurrent High CPU Processes:" -ForegroundColor Yellow
Get-Process | Where-Object { $_.CPU -gt 50 } | 
    Select-Object ProcessName, CPU, WorkingSet, StartTime |
    Sort-Object CPU -Descending |
    Format-Table -AutoSize

# 2. Safely end non-essential Chrome processes (keep main process)
Write-Host "`nOptimizing Chrome processes..." -ForegroundColor Yellow
$chromeProcesses = Get-Process chrome -ErrorAction SilentlyContinue
if ($chromeProcesses) {
    $chromeCount = $chromeProcesses.Count
    Write-Host "  Current Chrome processes: $chromeCount" -ForegroundColor White
    
    if ($chromeCount -gt 5) {
        Write-Host "  Too many Chrome processes detected, optimizing..." -ForegroundColor Yellow
        
        # Sort by start time, keep the oldest 3 processes (usually main processes)
        $oldestProcesses = $chromeProcesses | Sort-Object StartTime | Select-Object -First 3
        $processesToKeep = $oldestProcesses.Id
        
        # End other processes
        $stoppedCount = 0
        foreach ($proc in $chromeProcesses) {
            if ($proc.Id -notin $processesToKeep) {
                try {
                    Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                    $stoppedCount++
                    Write-Host "    [OK] Stopped: $($proc.ProcessName) (PID: $($proc.Id))" -ForegroundColor Green
                } catch {
                    Write-Host "    [ERROR] Cannot stop: $($proc.ProcessName) (PID: $($proc.Id))" -ForegroundColor Red
                }
            }
        }
        Write-Host "  Stopped $stoppedCount Chrome processes" -ForegroundColor Green
    } else {
        Write-Host "  [OK] Chrome process count is normal" -ForegroundColor Green
    }
}

# 3. Clean duplicate PowerShell processes
Write-Host "`nOptimizing PowerShell processes..." -ForegroundColor Yellow
$psProcesses = Get-Process powershell -ErrorAction SilentlyContinue
if ($psProcesses.Count -gt 3) {
    Write-Host "  Too many PowerShell processes detected, optimizing..." -ForegroundColor Yellow
    
    # Keep current process and oldest 2 processes
    $processesToKeep = @($PID)
    $oldestProcesses = $psProcesses | Where-Object { $_.Id -ne $PID } | Sort-Object StartTime | Select-Object -First 2
    $processesToKeep += $oldestProcesses.Id
    
    $stoppedCount = 0
    foreach ($proc in $psProcesses) {
        if ($proc.Id -notin $processesToKeep) {
            try {
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                $stoppedCount++
                Write-Host "    [OK] Stopped: $($proc.ProcessName) (PID: $($proc.Id))" -ForegroundColor Green
            } catch {
                Write-Host "    [ERROR] Cannot stop: $($proc.ProcessName) (PID: $($proc.Id))" -ForegroundColor Red
            }
        }
    }
    Write-Host "  Stopped $stoppedCount PowerShell processes" -ForegroundColor Green
} else {
    Write-Host "  [OK] PowerShell process count is normal" -ForegroundColor Green
}

# 4. Optimize system tray applications (optional)
Write-Host "`nOptimizing system tray applications..." -ForegroundColor Yellow
$trayApps = @(
    @{Name="BaiduNetdisk"; Description="Baidu Netdisk"},
    @{Name="WeChatAppEx"; Description="WeChat"},
    @{Name="QQ"; Description="QQ"},
    @{Name="TIM"; Description="TIM"}
)

foreach ($app in $trayApps) {
    $processes = Get-Process $app.Name -ErrorAction SilentlyContinue
    if ($processes) {
        Write-Host "  Found $($app.Description) running" -ForegroundColor White
        $answer = Read-Host "    Stop this process? (y/N)"
        if ($answer -eq 'y' -or $answer -eq 'Y') {
            try {
                Stop-Process -Name $app.Name -Force -ErrorAction SilentlyContinue
                Write-Host "    [OK] Stopped $($app.Description)" -ForegroundColor Green
            } catch {
                Write-Host "    [ERROR] Cannot stop $($app.Description)" -ForegroundColor Red
            }
        }
    }
}

# 5. Show optimized process status
Write-Host "`nOptimized Process Status:" -ForegroundColor Cyan
$totalProcesses = (Get-Process).Count
$highCpuProcesses = Get-Process | Where-Object { $_.CPU -gt 50 } | Measure-Object | Select-Object -ExpandProperty Count

Write-Host "  Total processes: $totalProcesses" -ForegroundColor White
Write-Host "  High CPU processes: $highCpuProcesses" -ForegroundColor $(if ($highCpuProcesses -gt 5) { 'Red' } else { 'Green' })

# 6. Memory usage
Write-Host "`nMemory Usage:" -ForegroundColor Cyan
$os = Get-CimInstance Win32_OperatingSystem
$totalMem = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeMem = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedMem = $totalMem - $freeMem
$usagePercent = [math]::Round(($usedMem / $totalMem) * 100, 1)

Write-Host "  Total memory: $totalMem GB" -ForegroundColor White
Write-Host "  Used memory: $usedMem GB ($usagePercent%)" -ForegroundColor $(if ($usagePercent -gt 80) { 'Red' } elseif ($usagePercent -gt 60) { 'Yellow' } else { 'Green' })
Write-Host "  Free memory: $freeMem GB" -ForegroundColor $(if ($freeMem -lt 1) { 'Red' } elseif ($freeMem -lt 2) { 'Yellow' } else { 'Green' })

Write-Host "`nProcess optimization completed!" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Cyan

if ($usagePercent -gt 80) {
    Write-Host "Recommendation: Memory usage too high, recommend restarting system or closing more programs" -ForegroundColor Red
} elseif ($highCpuProcesses -gt 5) {
    Write-Host "Recommendation: Too many high CPU processes, check for abnormal processes" -ForegroundColor Yellow
} else {
    Write-Host "Recommendation: System status is good" -ForegroundColor Green
}