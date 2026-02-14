# 系统卡死诊断脚本
Write-Host "=== 系统卡死诊断报告 ===" -ForegroundColor Cyan
Write-Host "诊断时间: $(Get-Date)" -ForegroundColor Yellow
Write-Host ""

# 1. 检查系统事件日志
Write-Host "1. 检查系统事件日志 (最近30分钟):" -ForegroundColor Green
$thirtyMinutesAgo = (Get-Date).AddMinutes(-30)
$systemEvents = Get-EventLog -LogName System -After $thirtyMinutesAgo -EntryType Error,Warning | Select-Object -First 10
if ($systemEvents) {
    $systemEvents | Format-Table TimeGenerated, EntryType, Source, @{Name="Message";Expression={$_.Message.Substring(0, [Math]::Min(50, $_.Message.Length))}} -AutoSize
} else {
    Write-Host "   无错误/警告事件" -ForegroundColor Green
}

Write-Host ""

# 2. 检查应用程序事件日志
Write-Host "2. 检查应用程序事件日志 (最近30分钟):" -ForegroundColor Green
$appEvents = Get-EventLog -LogName Application -After $thirtyMinutesAgo -EntryType Error,Warning | Select-Object -First 10
if ($appEvents) {
    $appEvents | Format-Table TimeGenerated, EntryType, Source, @{Name="Message";Expression={$_.Message.Substring(0, [Math]::Min(50, $_.Message.Length))}} -AutoSize
} else {
    Write-Host "   无错误/警告事件" -ForegroundColor Green
}

Write-Host ""

# 3. 检查当前高CPU进程
Write-Host "3. 当前高CPU进程 (>10%):" -ForegroundColor Green
$highCpuProcesses = Get-Process | Where-Object {$_.CPU -gt 10} | Sort-Object CPU -Descending
if ($highCpuProcesses) {
    $highCpuProcesses | Select-Object Name, @{Name="CPU%";Expression={[Math]::Round($_.CPU, 2)}}, @{Name="Memory(MB)";Expression={[Math]::Round($_.WorkingSet/1MB, 2)}}, Id, StartTime | Format-Table -AutoSize
} else {
    Write-Host "   无高CPU进程" -ForegroundColor Green
}

Write-Host ""

# 4. 检查内存使用
Write-Host "4. 内存使用情况:" -ForegroundColor Green
$memory = Get-CimInstance Win32_OperatingSystem
$totalMemory = [Math]::Round($memory.TotalVisibleMemorySize/1MB, 2)
$freeMemory = [Math]::Round($memory.FreePhysicalMemory/1MB, 2)
$usedMemory = $totalMemory - $freeMemory
$memoryPercent = [Math]::Round(($usedMemory / $totalMemory) * 100, 2)
Write-Host "   总内存: ${totalMemory}MB" -ForegroundColor White
Write-Host "   已用内存: ${usedMemory}MB" -ForegroundColor White
Write-Host "   可用内存: ${freeMemory}MB" -ForegroundColor White
Write-Host "   内存使用率: ${memoryPercent}%" -ForegroundColor $(if ($memoryPercent -gt 80) {"Red"} elseif ($memoryPercent -gt 60) {"Yellow"} else {"Green"})

Write-Host ""

# 5. 检查磁盘空间
Write-Host "5. 磁盘空间检查:" -ForegroundColor Green
Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $sizeGB = [Math]::Round($_.Size/1GB, 2)
    $freeGB = [Math]::Round($_.FreeSpace/1GB, 2)
    $usedGB = $sizeGB - $freeGB
    $percentFree = [Math]::Round(($freeGB / $sizeGB) * 100, 2)
    Write-Host "   $($_.DeviceID): ${usedGB}GB / ${sizeGB}GB (${percentFree}% 可用)" -ForegroundColor $(if ($percentFree -lt 10) {"Red"} elseif ($percentFree -lt 20) {"Yellow"} else {"Green"})
}

Write-Host ""

# 6. 检查网络连接
Write-Host "6. 网络连接状态:" -ForegroundColor Green
try {
    $pingResult = Test-Connection -ComputerName "8.8.8.8" -Count 2 -Quiet
    Write-Host "   网络连接: $(if ($pingResult) {"正常" -ForegroundColor Green} else {"异常" -ForegroundColor Red})"
} catch {
    Write-Host "   网络连接检查失败: $_" -ForegroundColor Red
}

Write-Host ""

# 7. 检查OpenClaw状态
Write-Host "7. OpenClaw状态检查:" -ForegroundColor Green
$openclawProcess = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object {$_.Path -like "*openclaw*"}
if ($openclawProcess) {
    Write-Host "   OpenClaw进程运行中 (PID: $($openclawProcess.Id))" -ForegroundColor Green
    Write-Host "   内存使用: $([Math]::Round($openclawProcess.WorkingSet/1MB, 2))MB" -ForegroundColor White
    Write-Host "   CPU使用: $([Math]::Round($openclawProcess.CPU, 2))%" -ForegroundColor White
} else {
    Write-Host "   OpenClaw进程未找到" -ForegroundColor Red
}

Write-Host ""

# 8. 检查浏览器进程
Write-Host "8. 浏览器进程检查:" -ForegroundColor Green
$chromeProcesses = Get-Process -Name "chrome" -ErrorAction SilentlyContinue
if ($chromeProcesses) {
    Write-Host "   Chrome进程数: $($chromeProcesses.Count)" -ForegroundColor White
    $totalChromeMemory = ($chromeProcesses | Measure-Object WorkingSet -Sum).Sum / 1MB
    Write-Host "   Chrome总内存: $([Math]::Round($totalChromeMemory, 2))MB" -ForegroundColor White
} else {
    Write-Host "   无Chrome进程" -ForegroundColor Yellow
}

Write-Host ""

# 9. 诊断结论和建议
Write-Host "=== 诊断结论和建议 ===" -ForegroundColor Cyan

# 分析事件日志
$crashEvents = $appEvents | Where-Object {$_.Source -eq "Application Hang" -or $_.Message -like "*挂起*" -or $_.Message -like "*停止*"}
if ($crashEvents) {
    Write-Host "⚠️ 发现应用程序崩溃事件:" -ForegroundColor Red
    $crashEvents | ForEach-Object {
        Write-Host "   - $($_.TimeGenerated): $($_.Source) - $($_.Message.Substring(0, [Math]::Min(100, $_.Message.Length)))..." -ForegroundColor Yellow
    }
}

# 分析高CPU进程
$excessiveCpu = $highCpuProcesses | Where-Object {$_.CPU -gt 100}
if ($excessiveCpu) {
    Write-Host "⚠️ 发现异常高CPU进程:" -ForegroundColor Red
    $excessiveCpu | ForEach-Object {
        Write-Host "   - $($_.Name) (PID: $($_.Id)): $([Math]::Round($_.CPU, 2))% CPU" -ForegroundColor Yellow
    }
}

# 内存分析
if ($memoryPercent -gt 80) {
    Write-Host "⚠️ 内存使用率过高: ${memoryPercent}%" -ForegroundColor Red
}

# 建议措施
Write-Host "`n🔧 建议修复措施:" -ForegroundColor Green

if ($excessiveCpu) {
    Write-Host "1. 重启高CPU进程:" -ForegroundColor White
    $excessiveCpu | ForEach-Object {
        Write-Host "   - $($_.Name) (PID: $($_.Id))" -ForegroundColor Yellow
    }
    Write-Host "   命令: Stop-Process -Id <PID> -Force" -ForegroundColor Gray
}

if ($memoryPercent -gt 80) {
    Write-Host "2. 清理内存:" -ForegroundColor White
    Write-Host "   - 关闭不必要的应用程序" -ForegroundColor Yellow
    Write-Host "   - 重启资源占用高的进程" -ForegroundColor Yellow
}

if ($chromeProcesses.Count -gt 15) {
    Write-Host "3. 清理Chrome进程:" -ForegroundColor White
    Write-Host "   - 关闭不必要的Chrome标签页" -ForegroundColor Yellow
    Write-Host "   - 重启Chrome浏览器" -ForegroundColor Yellow
}

Write-Host "4. 系统优化:" -ForegroundColor White
Write-Host "   - 运行磁盘清理" -ForegroundColor Yellow
Write-Host "   - 检查启动项" -ForegroundColor Yellow
Write-Host "   - 更新驱动程序" -ForegroundColor Yellow

Write-Host "`n📊 诊断完成" -ForegroundColor Cyan