# System Cleanup Script - Safe cleanup of temporary files and cache
Write-Host "Starting system cleanup..." -ForegroundColor Cyan

# 1. Clean temporary files (safe cleanup)
$tempPaths = @(
    "$env:TEMP",
    "$env:windir\Temp",
    "$env:LOCALAPPDATA\Temp"
)

foreach ($path in $tempPaths) {
    if (Test-Path $path) {
        Write-Host "Cleaning: $path" -ForegroundColor Yellow
        try {
            Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | 
                Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-1) } |
                Remove-Item -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] Done" -ForegroundColor Green
        } catch {
            Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# 2. Clean Chrome cache (keep important data)
$chromeCachePaths = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache2",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Media Cache"
)

foreach ($path in $chromeCachePaths) {
    if (Test-Path $path) {
        Write-Host "Cleaning Chrome cache: $path" -ForegroundColor Yellow
        try {
            # Only clean cache files, not important data
            Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | 
                Where-Object { $_.Extension -in @('.cache', '.tmp', '.dat') } |
                Remove-Item -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] Done" -ForegroundColor Green
        } catch {
            Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# 3. Clean system logs (keep last 3 days)
$logPaths = @(
    "$env:windir\Logs",
    "$env:ProgramData\Microsoft\Windows\WER"
)

foreach ($path in $logPaths) {
    if (Test-Path $path) {
        Write-Host "Cleaning system logs: $path" -ForegroundColor Yellow
        try {
            Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | 
                Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-3) } |
                Remove-Item -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] Done" -ForegroundColor Green
        } catch {
            Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# 4. Clean Recycle Bin
Write-Host "Emptying Recycle Bin..." -ForegroundColor Yellow
try {
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Host "  [OK] Recycle Bin emptied" -ForegroundColor Green
} catch {
    Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
}

# 5. Clean Windows Update cache
Write-Host "Cleaning Windows Update cache..." -ForegroundColor Yellow
try {
    if (Test-Path "$env:windir\SoftwareDistribution\Download") {
        Remove-Item -Path "$env:windir\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  [OK] Done" -ForegroundColor Green
    }
} catch {
    Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
}

# Show cleanup results
Write-Host "`nSystem cleanup completed!" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Cyan

# Show current disk space
$disk = Get-PSDrive C
$freeGB = [math]::Round($disk.Free / 1GB, 2)
$usedGB = [math]::Round(($disk.Used / 1GB), 2)
$totalGB = [math]::Round(($disk.Free + $disk.Used) / 1GB, 2)

Write-Host "C Drive Space Usage:" -ForegroundColor Cyan
Write-Host "  Total: $totalGB GB" -ForegroundColor White
Write-Host "  Used: $usedGB GB" -ForegroundColor Yellow
Write-Host "  Free: $freeGB GB" -ForegroundColor Green

Write-Host "`nRecommendations:" -ForegroundColor Cyan
if ($freeGB -lt 10) {
    Write-Host "  [WARNING] Low disk space, recommend further cleanup" -ForegroundColor Red
} elseif ($freeGB -lt 20) {
    Write-Host "  [WARNING] Disk space is tight" -ForegroundColor Yellow
} else {
    Write-Host "  [OK] Disk space is sufficient" -ForegroundColor Green
}