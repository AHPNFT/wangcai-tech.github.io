# Performance Monitor Script - Monitor system performance
param(
    [int]$IntervalSeconds = 60,
    [int]$MaxLogs = 100
)

Write-Host "Starting Performance Monitor..." -ForegroundColor Cyan
Write-Host "Monitoring interval: $IntervalSeconds seconds" -ForegroundColor White
Write-Host "Maximum logs: $MaxLogs" -ForegroundColor White
Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Yellow

# Create logs directory
$logDir = ".\performance_logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# Log file
$logFile = "$logDir\performance_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Performance thresholds
$thresholds = @{
    CPUWarning = 80
    CPUCritical = 90
    MemoryWarning = 80
    MemoryCritical = 90
    DiskWarning = 85
    DiskCritical = 95
    ProcessWarning = 200
    ProcessCritical = 250
}

# Monitoring loop
$iteration = 0
try {
    while ($true) {
        $iteration++
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        Write-Host "`n[$timestamp] Iteration: $iteration" -ForegroundColor Cyan
        
        # 1. CPU Usage
        $cpu = Get-Counter '\Processor(_Total)\% Processor Time' | 
               Select-Object -ExpandProperty CounterSamples | 
               Select-Object -ExpandProperty CookedValue
        
        $cpuColor = if ($cpu -gt $thresholds.CPUCritical) { 'Red' } 
                    elseif ($cpu -gt $thresholds.CPUWarning) { 'Yellow' } 
                    else { 'Green' }
        
        Write-Host "  CPU Usage: $([math]::Round($cpu, 1))%" -ForegroundColor $cpuColor
        
        # 2. Memory Usage
        $os = Get-CimInstance Win32_OperatingSystem
        $totalMem = $os.TotalVisibleMemorySize / 1MB
        $freeMem = $os.FreePhysicalMemory / 1MB
        $usedMem = $totalMem - $freeMem
        $memPercent = [math]::Round(($usedMem / $totalMem) * 100, 1)
        
        $memColor = if ($memPercent -gt $thresholds.MemoryCritical) { 'Red' } 
                    elseif ($memPercent -gt $thresholds.MemoryWarning) { 'Yellow' } 
                    else { 'Green' }
        
        Write-Host "  Memory: $([math]::Round($usedMem, 1))/$([math]::Round($totalMem, 1)) GB ($memPercent%)" -ForegroundColor $memColor
        
        # 3. Disk Space
        $disk = Get-PSDrive C
        $totalDisk = ($disk.Free + $disk.Used) / 1GB
        $freeDisk = $disk.Free / 1GB
        $usedDisk = $disk.Used / 1GB
        $diskPercent = [math]::Round(($usedDisk / $totalDisk) * 100, 1)
        
        $diskColor = if ($diskPercent -gt $thresholds.DiskCritical) { 'Red' } 
                     elseif ($diskPercent -gt $thresholds.DiskWarning) { 'Yellow' } 
                     else { 'Green' }
        
        Write-Host "  Disk C: $([math]::Round($usedDisk, 1))/$([math]::Round($totalDisk, 1)) GB ($diskPercent%)" -ForegroundColor $diskColor
        
        # 4. Process Count
        $processCount = (Get-Process).Count
        
        $processColor = if ($processCount -gt $thresholds.ProcessCritical) { 'Red' } 
                        elseif ($processCount -gt $thresholds.ProcessWarning) { 'Yellow' } 
                        else { 'Green' }
        
        Write-Host "  Processes: $processCount" -ForegroundColor $processColor
        
        # 5. Top 5 CPU processes
        Write-Host "  Top 5 CPU Processes:" -ForegroundColor White
        Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 | 
            ForEach-Object {
                $cpuValue = [math]::Round($_.CPU, 1)
                $memMB = [math]::Round($_.WorkingSet / 1MB, 1)
                Write-Host "    - $($_.ProcessName): $cpuValue% CPU, $memMB MB" -ForegroundColor Gray
            }
        
        # 6. Check for critical conditions
        $alerts = @()
        
        if ($cpu -gt $thresholds.CPUCritical) {
            $alerts += "CPU usage critical: $([math]::Round($cpu, 1))%"
        }
        
        if ($memPercent -gt $thresholds.MemoryCritical) {
            $alerts += "Memory usage critical: $memPercent%"
        }
        
        if ($processCount -gt $thresholds.ProcessCritical) {
            $alerts += "Too many processes: $processCount"
        }
        
        # Log to file
        $logEntry = @"
[$timestamp]
CPU: $([math]::Round($cpu, 1))%
Memory: $([math]::Round($usedMem, 1))/$([math]::Round($totalMem, 1)) GB ($memPercent%)
Disk: $([math]::Round($usedDisk, 1))/$([math]::Round($totalDisk, 1)) GB ($diskPercent%)
Processes: $processCount
Alerts: $(if ($alerts.Count -gt 0) { $alerts -join '; ' } else { 'None' })

"@
        
        Add-Content -Path $logFile -Value $logEntry
        
        # Rotate logs if needed
        $logFiles = Get-ChildItem -Path $logDir -Filter "performance_*.log" | Sort-Object LastWriteTime
        if ($logFiles.Count -gt $MaxLogs) {
            $filesToDelete = $logFiles.Count - $MaxLogs
            $logFiles | Select-Object -First $filesToDelete | Remove-Item -Force
        }
        
        # Show alerts
        if ($alerts.Count -gt 0) {
            Write-Host "`n[ALERTS]" -ForegroundColor Red
            foreach ($alert in $alerts) {
                Write-Host "  ⚠️ $alert" -ForegroundColor Red
            }
            
            # Suggest actions for critical alerts
            if ($cpu -gt $thresholds.CPUCritical) {
                Write-Host "  Suggested action: Check high CPU processes" -ForegroundColor Yellow
            }
            if ($memPercent -gt $thresholds.MemoryCritical) {
                Write-Host "  Suggested action: Clean memory or restart applications" -ForegroundColor Yellow
            }
        }
        
        # Wait for next interval
        Write-Host "`nNext check in $IntervalSeconds seconds..." -ForegroundColor Gray
        Start-Sleep -Seconds $IntervalSeconds
    }
}
catch {
    Write-Host "`nMonitoring stopped: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    Write-Host "`nPerformance monitoring stopped." -ForegroundColor Cyan
    Write-Host "Log file: $logFile" -ForegroundColor White
    Write-Host "Total iterations: $iteration" -ForegroundColor White
}