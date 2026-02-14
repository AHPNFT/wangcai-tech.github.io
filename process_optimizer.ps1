# 进程优化脚本 - 安全优化系统进程
Write-Host "开始进程优化..." -ForegroundColor Cyan

# 1. 显示当前高CPU进程
Write-Host "`n当前高CPU进程:" -ForegroundColor Yellow
Get-Process | Where-Object { $_.CPU -gt 50 } | 
    Select-Object ProcessName, CPU, WorkingSet, StartTime |
    Sort-Object CPU -Descending |
    Format-Table -AutoSize

# 2. 安全结束非必要的Chrome进程（保留主进程）
Write-Host "`n优化Chrome进程..." -ForegroundColor Yellow
$chromeProcesses = Get-Process chrome -ErrorAction SilentlyContinue
if ($chromeProcesses) {
    $chromeCount = $chromeProcesses.Count
    Write-Host "  当前Chrome进程数: $chromeCount" -ForegroundColor White
    
    if ($chromeCount -gt 5) {
        Write-Host "  检测到过多Chrome进程，进行优化..." -ForegroundColor Yellow
        
        # 按启动时间排序，保留最早的3个进程（通常是主进程）
        $oldestProcesses = $chromeProcesses | Sort-Object StartTime | Select-Object -First 3
        $processesToKeep = $oldestProcesses.Id
        
        # 结束其他进程
        $stoppedCount = 0
        foreach ($proc in $chromeProcesses) {
            if ($proc.Id -notin $processesToKeep) {
                try {
                    Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                    $stoppedCount++
                    Write-Host "    ✓ 结束进程: $($proc.ProcessName) (PID: $($proc.Id))" -ForegroundColor Green
                } catch {
                    Write-Host "    ✗ 无法结束进程: $($proc.ProcessName) (PID: $($proc.Id))" -ForegroundColor Red
                }
            }
        }
        Write-Host "  已结束 $stoppedCount 个Chrome进程" -ForegroundColor Green
    } else {
        Write-Host "  ✓ Chrome进程数量正常" -ForegroundColor Green
    }
}

# 3. 清理重复的PowerShell进程
Write-Host "`n优化PowerShell进程..." -ForegroundColor Yellow
$psProcesses = Get-Process powershell -ErrorAction SilentlyContinue
if ($psProcesses.Count -gt 3) {
    Write-Host "  检测到过多PowerShell进程，进行优化..." -ForegroundColor Yellow
    
    # 保留当前进程和最早的2个进程
    $processesToKeep = @($PID)
    $oldestProcesses = $psProcesses | Where-Object { $_.Id -ne $PID } | Sort-Object StartTime | Select-Object -First 2
    $processesToKeep += $oldestProcesses.Id
    
    $stoppedCount = 0
    foreach ($proc in $psProcesses) {
        if ($proc.Id -notin $processesToKeep) {
            try {
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                $stoppedCount++
                Write-Host "    ✓ 结束进程: $($proc.ProcessName) (PID: $($proc.Id))" -ForegroundColor Green
            } catch {
                Write-Host "    ✗ 无法结束进程: $($proc.ProcessName) (PID: $($proc.Id))" -ForegroundColor Red
            }
        }
    }
    Write-Host "  已结束 $stoppedCount 个PowerShell进程" -ForegroundColor Green
} else {
    Write-Host "  ✓ PowerShell进程数量正常" -ForegroundColor Green
}

# 4. 优化系统托盘程序（可选）
Write-Host "`n优化系统托盘程序..." -ForegroundColor Yellow
$trayApps = @(
    @{Name="BaiduNetdisk"; Description="百度网盘"},
    @{Name="迅雷"; Description="迅雷下载"},
    @{Name="WeChatAppEx"; Description="微信"},
    @{Name="QQ"; Description="QQ"},
    @{Name="TIM"; Description="TIM"}
)

foreach ($app in $trayApps) {
    $processes = Get-Process $app.Name -ErrorAction SilentlyContinue
    if ($processes) {
        Write-Host "  发现 $($app.Description) 正在运行" -ForegroundColor White
        $answer = Read-Host "    是否结束此进程？(y/N)"
        if ($answer -eq 'y' -or $answer -eq 'Y') {
            try {
                Stop-Process -Name $app.Name -Force -ErrorAction SilentlyContinue
                Write-Host "    ✓ 已结束 $($app.Description)" -ForegroundColor Green
            } catch {
                Write-Host "    ✗ 无法结束 $($app.Description)" -ForegroundColor Red
            }
        }
    }
}

# 5. 显示优化后的进程状态
Write-Host "`n优化后的进程状态:" -ForegroundColor Cyan
$totalProcesses = (Get-Process).Count
$highCpuProcesses = Get-Process | Where-Object { $_.CPU -gt 50 } | Measure-Object | Select-Object -ExpandProperty Count

Write-Host "  总进程数: $totalProcesses" -ForegroundColor White
Write-Host "  高CPU进程数: $highCpuProcesses" -ForegroundColor $(if ($highCpuProcesses -gt 5) { 'Red' } else { 'Green' })

# 6. 内存使用情况
Write-Host "`n内存使用情况:" -ForegroundColor Cyan
$os = Get-CimInstance Win32_OperatingSystem
$totalMem = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeMem = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedMem = $totalMem - $freeMem
$usagePercent = [math]::Round(($usedMem / $totalMem) * 100, 1)

Write-Host "  总内存: $totalMem GB" -ForegroundColor White
Write-Host "  已使用: $usedMem GB ($usagePercent%)" -ForegroundColor $(if ($usagePercent -gt 80) { 'Red' } elseif ($usagePercent -gt 60) { 'Yellow' } else { 'Green' })
Write-Host "  可用内存: $freeMem GB" -ForegroundColor $(if ($freeMem -lt 1) { 'Red' } elseif ($freeMem -lt 2) { 'Yellow' } else { 'Green' })

Write-Host "`n进程优化完成！" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Cyan

if ($usagePercent -gt 80) {
    Write-Host "建议: 内存使用率过高，建议重启系统或关闭更多程序" -ForegroundColor Red
} elseif ($highCpuProcesses -gt 5) {
    Write-Host "建议: 高CPU进程较多，建议检查是否有异常进程" -ForegroundColor Yellow
} else {
    Write-Host "建议: 系统状态良好" -ForegroundColor Green
}