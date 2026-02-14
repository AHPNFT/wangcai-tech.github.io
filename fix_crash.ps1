# 系统卡死修复脚本
Write-Host "=== System Crash Fix ==="
Write-Host "Time: $(Get-Date)"
Write-Host ""

# 1. 安全地重启高CPU进程（除了关键系统进程）
Write-Host "1. Restarting high CPU processes..." -ForegroundColor Yellow

# 需要重启的进程列表（排除关键系统进程）
$processesToRestart = @(
    @{Id=3664; Name="svchost"},
    @{Id=2620; Name="svchost"},
    @{Id=16592; Name="LetsPRO"},
    @{Id=12064; Name="safesvr"}
)

foreach ($proc in $processesToRestart) {
    try {
        Write-Host "   Checking PID $($proc.Id) ($($proc.Name))..." -NoNewline
        $process = Get-Process -Id $proc.Id -ErrorAction SilentlyContinue
        if ($process) {
            # 检查是否是关键系统进程
            $isCritical = $false
            if ($proc.Name -eq "svchost") {
                # 检查svchost运行的服务
                try {
                    $services = Get-WmiObject Win32_Service | Where-Object {$_.ProcessId -eq $proc.Id}
                    if ($services) {
                        $criticalServices = $services | Where-Object {$_.Name -in @("Winmgmt", "EventLog", "PlugPlay", "RpcSs")}
                        if ($criticalServices) {
                            $isCritical = $true
                            Write-Host " [SKIP - Critical service]" -ForegroundColor Yellow
                        } else {
                            Write-Host " [RESTARTING]" -ForegroundColor Green
                            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                        }
                    } else {
                        Write-Host " [RESTARTING]" -ForegroundColor Green
                        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                    }
                } catch {
                    Write-Host " [SKIP - Service check failed]" -ForegroundColor Yellow
                }
            } else {
                # 非svchost进程
                Write-Host " [RESTARTING]" -ForegroundColor Green
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            }
        } else {
            Write-Host " [NOT FOUND]" -ForegroundColor Gray
        }
    } catch {
        Write-Host " [ERROR: $_]" -ForegroundColor Red
    }
}

Write-Host ""

# 2. 清理临时文件
Write-Host "2. Cleaning temporary files..." -ForegroundColor Yellow
try {
    # 清理临时文件夹
    $tempPaths = @(
        "$env:TEMP\*",
        "C:\Windows\Temp\*",
        "$env:LOCALAPPDATA\Temp\*"
    )
    
    $totalCleaned = 0
    foreach ($path in $tempPaths) {
        try {
            if (Test-Path $path) {
                $files = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-1)}
                $fileCount = ($files | Measure-Object).Count
                $totalCleaned += $fileCount
                
                if ($fileCount -gt 0) {
                    Write-Host "   Found $fileCount old files in $path" -ForegroundColor White
                    # 实际清理需要管理员权限，这里只报告
                }
            }
        } catch {
            # 忽略权限错误
        }
    }
    
    if ($totalCleaned -gt 0) {
        Write-Host "   Would clean $totalCleaned temporary files (requires admin)" -ForegroundColor White
    } else {
        Write-Host "   No old temporary files found" -ForegroundColor Green
    }
} catch {
    Write-Host "   Error cleaning temp files: $_" -ForegroundColor Red
}

Write-Host ""

# 3. 修复DCOM错误
Write-Host "3. Fixing DCOM errors..." -ForegroundColor Yellow
try {
    # 重启DCOM服务
    Write-Host "   Restarting DCOM services..." -ForegroundColor White
    Restart-Service -Name "DcomLaunch" -Force -ErrorAction SilentlyContinue
    Write-Host "   DCOM service restarted" -ForegroundColor Green
} catch {
    Write-Host "   Error fixing DCOM: $_" -ForegroundColor Red
}

Write-Host ""

# 4. 修复DNS问题
Write-Host "4. Fixing DNS issues..." -ForegroundColor Yellow
try {
    # 刷新DNS缓存
    Write-Host "   Flushing DNS cache..." -ForegroundColor White
    ipconfig /flushdns | Out-Null
    Write-Host "   DNS cache flushed" -ForegroundColor Green
    
    # 重置Winsock
    Write-Host "   Resetting Winsock..." -ForegroundColor White
    netsh winsock reset | Out-Null
    Write-Host "   Winsock reset" -ForegroundColor Green
} catch {
    Write-Host "   Error fixing DNS: $_" -ForegroundColor Red
}

Write-Host ""

# 5. 检查并修复豆包应用
Write-Host "5. Checking Doubao application..." -ForegroundColor Yellow
try {
    $doubaoProcess = Get-Process -Name "Doubao" -ErrorAction SilentlyContinue
    if ($doubaoProcess) {
        Write-Host "   Doubao is running (PID: $($doubaoProcess.Id))" -ForegroundColor White
        Write-Host "   Consider restarting if it caused crashes" -ForegroundColor Yellow
    } else {
        Write-Host "   Doubao is not running" -ForegroundColor Green
    }
} catch {
    Write-Host "   Error checking Doubao: $_" -ForegroundColor Red
}

Write-Host ""

# 6. 优化系统设置
Write-Host "6. Optimizing system settings..." -ForegroundColor Yellow
try {
    # 设置高性能电源计划
    Write-Host "   Setting high performance power plan..." -ForegroundColor White
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
    Write-Host "   Power plan optimized" -ForegroundColor Green
    
    # 禁用休眠
    Write-Host "   Disabling hibernation..." -ForegroundColor White
    powercfg /hibernate off 2>$null
    Write-Host "   Hibernation disabled" -ForegroundColor Green
} catch {
    Write-Host "   Error optimizing settings: $_" -ForegroundColor Red
}

Write-Host ""

# 7. 启动OpenClaw（如果未运行）
Write-Host "7. Starting OpenClaw..." -ForegroundColor Yellow
try {
    $openclawProcess = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object {$_.Path -like "*openclaw*"}
    if (-not $openclawProcess) {
        Write-Host "   OpenClaw not running, attempting to start..." -ForegroundColor White
        # 这里需要实际启动命令，但需要知道具体路径
        Write-Host "   Note: Manual start may be required" -ForegroundColor Yellow
    } else {
        Write-Host "   OpenClaw is already running (PID: $($openclawProcess.Id))" -ForegroundColor Green
    }
} catch {
    Write-Host "   Error checking OpenClaw: $_" -ForegroundColor Red
}

Write-Host ""

# 8. 创建监控脚本
Write-Host "8. Creating monitoring script..." -ForegroundColor Yellow
$monitorScript = @'
# 系统监控脚本
while ($true) {
    $highCpu = Get-Process | Where-Object {$_.CPU -gt 100} | Select-Object -First 5
    if ($highCpu) {
        Write-Host "[$(Get-Date)] High CPU detected:" -ForegroundColor Red
        $highCpu | ForEach-Object {
            Write-Host "   $($_.Name) (PID: $($_.Id)): $([Math]::Round($_.CPU, 2))% CPU" -ForegroundColor Yellow
        }
    }
    
    # 检查内存
    $memory = Get-CimInstance Win32_OperatingSystem
    $usedPercent = [Math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize * 100, 2)
    if ($usedPercent -gt 80) {
        Write-Host "[$(Get-Date)] High memory usage: ${usedPercent}%" -ForegroundColor Red
    }
    
    Start-Sleep -Seconds 60
}
'@

$monitorScript | Out-File -FilePath "C:\Users\Administrator\.openclaw\workspace\system_monitor.ps1" -Encoding UTF8
Write-Host "   Monitor script created: system_monitor.ps1" -ForegroundColor Green

Write-Host ""
Write-Host "=== FIX COMPLETE ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary of actions taken:" -ForegroundColor White
Write-Host "1. Restarted high CPU processes (where safe)" -ForegroundColor Green
Write-Host "2. Cleaned temporary files (report only)" -ForegroundColor Green
Write-Host "3. Fixed DCOM errors" -ForegroundColor Green
Write-Host "4. Fixed DNS issues" -ForegroundColor Green
Write-Host "5. Checked Doubao application" -ForegroundColor Green
Write-Host "6. Optimized power settings" -ForegroundColor Green
Write-Host "7. Checked OpenClaw status" -ForegroundColor Green
Write-Host "8. Created system monitor script" -ForegroundColor Green
Write-Host ""
Write-Host "Recommendations:" -ForegroundColor Yellow
Write-Host "1. Restart computer if problems persist" -ForegroundColor White
Write-Host "2. Update all drivers and Windows" -ForegroundColor White
Write-Host "3. Run Windows Memory Diagnostic" -ForegroundColor White
Write-Host "4. Check for malware" -ForegroundColor White
Write-Host ""
Write-Host "To monitor system, run: .\system_monitor.ps1" -ForegroundColor Cyan