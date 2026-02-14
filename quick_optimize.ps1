# Quick System Optimizer - One-click system optimization
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "QUICK SYSTEM OPTIMIZER" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

# Record start time
$startTime = Get-Date

# 1. System Cleanup
Write-Host "`n[1/4] Running System Cleanup..." -ForegroundColor Cyan
try {
    & ".\system_cleanup_en.ps1"
    Write-Host "  [OK] System cleanup completed" -ForegroundColor Green
} catch {
    Write-Host "  [ERROR] System cleanup failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. Process Optimization
Write-Host "`n[2/4] Running Process Optimization..." -ForegroundColor Cyan
try {
    & ".\process_optimizer_en.ps1"
    Write-Host "  [OK] Process optimization completed" -ForegroundColor Green
} catch {
    Write-Host "  [ERROR] Process optimization failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Check current performance
Write-Host "`n[3/4] Checking Current Performance..." -ForegroundColor Cyan

# CPU
$cpu = Get-Counter '\Processor(_Total)\% Processor Time' | 
       Select-Object -ExpandProperty CounterSamples | 
       Select-Object -ExpandProperty CookedValue

# Memory
$os = Get-CimInstance Win32_OperatingSystem
$totalMem = $os.TotalVisibleMemorySize / 1MB
$freeMem = $os.FreePhysicalMemory / 1MB
$usedMem = $totalMem - $freeMem
$memPercent = [math]::Round(($usedMem / $totalMem) * 100, 1)

# Disk
$disk = Get-PSDrive C
$totalDisk = ($disk.Free + $disk.Used) / 1GB
$freeDisk = $disk.Free / 1GB
$usedDisk = $disk.Used / 1GB
$diskPercent = [math]::Round(($usedDisk / $totalDisk) * 100, 1)

# Processes
$processCount = (Get-Process).Count

Write-Host "  CPU Usage: $([math]::Round($cpu, 1))%" -ForegroundColor $(if ($cpu -gt 80) { 'Red' } elseif ($cpu -gt 60) { 'Yellow' } else { 'Green' })
Write-Host "  Memory: $([math]::Round($usedMem, 1))/$([math]::Round($totalMem, 1)) GB ($memPercent%)" -ForegroundColor $(if ($memPercent -gt 80) { 'Red' } elseif ($memPercent -gt 60) { 'Yellow' } else { 'Green' })
Write-Host "  Disk C: $([math]::Round($usedDisk, 1))/$([math]::Round($totalDisk, 1)) GB ($diskPercent%)" -ForegroundColor $(if ($diskPercent -gt 85) { 'Red' } elseif ($diskPercent -gt 70) { 'Yellow' } else { 'Green' })
Write-Host "  Processes: $processCount" -ForegroundColor $(if ($processCount -gt 200) { 'Red' } elseif ($processCount -gt 150) { 'Yellow' } else { 'Green' })

# 4. Create optimization report
Write-Host "`n[4/4] Creating Optimization Report..." -ForegroundColor Cyan

$endTime = Get-Date
$executionTime = $endTime - $startTime

$report = @"
========================================
SYSTEM OPTIMIZATION REPORT
========================================
Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Execution Time: $($executionTime.ToString('hh\:mm\:ss'))

PERFORMANCE METRICS:
- CPU Usage: $([math]::Round($cpu, 1))%
- Memory Usage: $([math]::Round($usedMem, 1))/$([math]::Round($totalMem, 1)) GB ($memPercent%)
- Disk Usage: $([math]::Round($usedDisk, 1))/$([math]::Round($totalDisk, 1)) GB ($diskPercent%)
- Process Count: $processCount

OPTIMIZATION STATUS:
$(if ($cpu -lt 60 -and $memPercent -lt 70 -and $processCount -lt 180) {
    "✅ SYSTEM OPTIMIZED - Performance is good"
} elseif ($cpu -lt 80 -and $memPercent -lt 80 -and $processCount -lt 220) {
    "⚠️ SYSTEM ACCEPTABLE - Some optimization needed"
} else {
    "❌ SYSTEM NEEDS ATTENTION - Significant optimization required"
})

RECOMMENDATIONS:
$(
if ($cpu -gt 80) {
    "- Reduce CPU usage by closing unnecessary applications`n"
}
if ($memPercent -gt 80) {
    "- Free up memory by closing memory-intensive programs`n"
}
if ($processCount -gt 200) {
    "- Reduce number of running processes`n"
}
if ($diskPercent -gt 85) {
    "- Clean up disk space`n"
}
if ($cpu -lt 60 -and $memPercent -lt 70 -and $processCount -lt 180) {
    "- System is well optimized, maintain current state`n"
}
)

NEXT STEPS:
1. Run '.\performance_monitor.ps1' for continuous monitoring
2. Run '.\system_cleanup_en.ps1' daily for maintenance
3. Run '.\process_optimizer_en.ps1' when system feels slow

CREATED FILES:
- system_cleanup_en.ps1 - System cleanup script
- process_optimizer_en.ps1 - Process optimization script  
- performance_monitor.ps1 - Performance monitoring script
- quick_optimize.ps1 - This optimization script

========================================
"@

# Save report
$reportFile = ".\optimization_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$report | Out-File -FilePath $reportFile -Encoding UTF8

Write-Host "  [OK] Report saved to: $reportFile" -ForegroundColor Green

# Display summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "OPTIMIZATION COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total time: $($executionTime.ToString('hh\:mm\:ss'))" -ForegroundColor White
Write-Host "Report: $reportFile" -ForegroundColor White
Write-Host "`nTo start performance monitoring:" -ForegroundColor Yellow
Write-Host "  .\performance_monitor.ps1" -ForegroundColor White
Write-Host "`nTo run quick optimization again:" -ForegroundColor Yellow
Write-Host "  .\quick_optimize.ps1" -ForegroundColor White