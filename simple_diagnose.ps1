# 简化版系统诊断脚本
Write-Host "=== System Crash Diagnosis Report ==="
Write-Host "Time: $(Get-Date)"
Write-Host ""

# 1. Check system events
Write-Host "1. System Events (last 30 min):"
$thirtyMinutesAgo = (Get-Date).AddMinutes(-30)
try {
    $systemEvents = Get-EventLog -LogName System -After $thirtyMinutesAgo -EntryType Error,Warning -Newest 5
    if ($systemEvents) {
        foreach ($event in $systemEvents) {
            $shortMsg = $event.Message.Substring(0, [Math]::Min(80, $event.Message.Length))
            Write-Host "   $($event.TimeGenerated) [$($event.EntryType)] $($event.Source): $shortMsg..."
        }
    } else {
        Write-Host "   No errors/warnings found"
    }
} catch {
    Write-Host "   Error checking system events: $_"
}

Write-Host ""

# 2. Check application events
Write-Host "2. Application Events (last 30 min):"
try {
    $appEvents = Get-EventLog -LogName Application -After $thirtyMinutesAgo -EntryType Error,Warning -Newest 5
    if ($appEvents) {
        foreach ($event in $appEvents) {
            $shortMsg = $event.Message.Substring(0, [Math]::Min(80, $event.Message.Length))
            Write-Host "   $($event.TimeGenerated) [$($event.EntryType)] $($event.Source): $shortMsg..."
        }
    } else {
        Write-Host "   No errors/warnings found"
    }
} catch {
    Write-Host "   Error checking application events: $_"
}

Write-Host ""

# 3. Check high CPU processes
Write-Host "3. High CPU Processes (>10%):"
try {
    $highCpuProcesses = Get-Process | Where-Object {$_.CPU -gt 10} | Sort-Object CPU -Descending | Select-Object -First 5
    if ($highCpuProcesses) {
        foreach ($proc in $highCpuProcesses) {
            $cpu = [Math]::Round($proc.CPU, 2)
            $memoryMB = [Math]::Round($proc.WorkingSet / 1MB, 2)
            Write-Host "   $($proc.Name) (PID: $($proc.Id)): $cpu% CPU, $memoryMB MB"
        }
    } else {
        Write-Host "   No high CPU processes found"
    }
} catch {
    Write-Host "   Error checking processes: $_"
}

Write-Host ""

# 4. Check memory
Write-Host "4. Memory Usage:"
try {
    $memory = Get-CimInstance Win32_OperatingSystem
    $totalMB = [Math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
    $freeMB = [Math]::Round($memory.FreePhysicalMemory / 1MB, 2)
    $usedMB = $totalMB - $freeMB
    $percent = [Math]::Round(($usedMB / $totalMB) * 100, 2)
    
    Write-Host "   Total: ${totalMB}MB"
    Write-Host "   Used: ${usedMB}MB"
    Write-Host "   Free: ${freeMB}MB"
    Write-Host "   Usage: ${percent}%"
    
    if ($percent -gt 80) {
        Write-Host "   WARNING: High memory usage!" -ForegroundColor Red
    }
} catch {
    Write-Host "   Error checking memory: $_"
}

Write-Host ""

# 5. Check disk space
Write-Host "5. Disk Space:"
try {
    $disks = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"
    foreach ($disk in $disks) {
        $sizeGB = [Math]::Round($disk.Size / 1GB, 2)
        $freeGB = [Math]::Round($disk.FreeSpace / 1GB, 2)
        $usedGB = $sizeGB - $freeGB
        $percentFree = [Math]::Round(($freeGB / $sizeGB) * 100, 2)
        
        Write-Host "   $($disk.DeviceID): ${usedGB}GB / ${sizeGB}GB (${percentFree}% free)"
        
        if ($percentFree -lt 10) {
            Write-Host "   WARNING: Low disk space!" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "   Error checking disk space: $_"
}

Write-Host ""

# 6. Check OpenClaw
Write-Host "6. OpenClaw Status:"
try {
    $openclawProcess = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object {$_.Path -like "*openclaw*"}
    if ($openclawProcess) {
        $memoryMB = [Math]::Round($openclawProcess.WorkingSet / 1MB, 2)
        $cpu = [Math]::Round($openclawProcess.CPU, 2)
        Write-Host "   Running (PID: $($openclawProcess.Id))"
        Write-Host "   Memory: ${memoryMB}MB, CPU: ${cpu}%"
    } else {
        Write-Host "   Not running"
    }
} catch {
    Write-Host "   Error checking OpenClaw: $_"
}

Write-Host ""

# 7. Summary
Write-Host "=== DIAGNOSIS SUMMARY ==="

# Find crash events
$crashFound = $false
if ($appEvents) {
    $crashEvents = $appEvents | Where-Object {$_.Source -eq "Application Hang" -or $_.Message -like "*hang*" -or $_.Message -like "*stopped*"}
    if ($crashEvents) {
        Write-Host "CRASH DETECTED:" -ForegroundColor Red
        foreach ($event in $crashEvents) {
            Write-Host "   $($event.TimeGenerated): $($event.Source)" -ForegroundColor Yellow
            $shortMsg = $event.Message.Substring(0, [Math]::Min(100, $event.Message.Length))
            Write-Host "   $shortMsg..." -ForegroundColor Yellow
        }
        $crashFound = $true
    }
}

# Check for high CPU
$excessiveCpu = $highCpuProcesses | Where-Object {$_.CPU -gt 100}
if ($excessiveCpu) {
    Write-Host "HIGH CPU DETECTED:" -ForegroundColor Red
    foreach ($proc in $excessiveCpu) {
        $cpu = [Math]::Round($proc.CPU, 2)
        Write-Host "   $($proc.Name) (PID: $($proc.Id)): $cpu% CPU" -ForegroundColor Yellow
    }
    $crashFound = $true
}

if (-not $crashFound) {
    Write-Host "No obvious crash causes found in logs" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== RECOMMENDED ACTIONS ==="

if ($excessiveCpu) {
    Write-Host "1. Restart high CPU processes:"
    foreach ($proc in $excessiveCpu) {
        Write-Host "   Stop-Process -Id $($proc.Id) -Force"
    }
}

Write-Host "2. Clear temporary files:"
Write-Host "   Cleanmgr.exe"

Write-Host "3. Check for updates:"
Write-Host "   Windows Update"

Write-Host "4. Monitor system:"
Write-Host "   Use Task Manager to monitor resource usage"

Write-Host ""
Write-Host "Diagnosis complete"