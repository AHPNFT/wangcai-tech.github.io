# 系统清理脚本 - 安全清理临时文件和缓存
Write-Host "开始系统清理..." -ForegroundColor Cyan

# 1. 清理临时文件（安全清理）
$tempPaths = @(
    "$env:TEMP",
    "$env:windir\Temp",
    "$env:LOCALAPPDATA\Temp"
)

foreach ($path in $tempPaths) {
    if (Test-Path $path) {
        Write-Host "清理: $path" -ForegroundColor Yellow
        try {
            Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | 
                Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-1) } |
                Remove-Item -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ 完成" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ 错误: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# 2. 清理Chrome缓存（保留重要数据）
$chromeCachePaths = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache2",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Media Cache"
)

foreach ($path in $chromeCachePaths) {
    if (Test-Path $path) {
        Write-Host "清理Chrome缓存: $path" -ForegroundColor Yellow
        try {
            # 只清理缓存文件，不清理重要数据
            Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | 
                Where-Object { $_.Extension -in @('.cache', '.tmp', '.dat') } |
                Remove-Item -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ 完成" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ 错误: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# 3. 清理系统日志（保留最近3天）
$logPaths = @(
    "$env:windir\Logs",
    "$env:ProgramData\Microsoft\Windows\WER"
)

foreach ($path in $logPaths) {
    if (Test-Path $path) {
        Write-Host "清理系统日志: $path" -ForegroundColor Yellow
        try {
            Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | 
                Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-3) } |
                Remove-Item -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ 完成" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ 错误: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# 4. 清理回收站
Write-Host "清空回收站..." -ForegroundColor Yellow
try {
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ 回收站已清空" -ForegroundColor Green
} catch {
    Write-Host "  ✗ 错误: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. 清理Windows更新缓存
Write-Host "清理Windows更新缓存..." -ForegroundColor Yellow
try {
    if (Test-Path "$env:windir\SoftwareDistribution\Download") {
        Remove-Item -Path "$env:windir\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ 完成" -ForegroundColor Green
    }
} catch {
    Write-Host "  ✗ 错误: $($_.Exception.Message)" -ForegroundColor Red
}

# 统计清理结果
Write-Host "`n系统清理完成！" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Cyan

# 显示当前磁盘空间
$disk = Get-PSDrive C
$freeGB = [math]::Round($disk.Free / 1GB, 2)
$usedGB = [math]::Round(($disk.Used / 1GB), 2)
$totalGB = [math]::Round(($disk.Free + $disk.Used) / 1GB, 2)

Write-Host "C盘空间使用情况:" -ForegroundColor Cyan
Write-Host "  总空间: $totalGB GB" -ForegroundColor White
Write-Host "  已使用: $usedGB GB" -ForegroundColor Yellow
Write-Host "  可用空间: $freeGB GB" -ForegroundColor Green

Write-Host "`n建议:" -ForegroundColor Cyan
if ($freeGB -lt 10) {
    Write-Host "  [警告] 磁盘空间不足，建议进一步清理" -ForegroundColor Red
} elseif ($freeGB -lt 20) {
    Write-Host "  [警告] 磁盘空间较紧张" -ForegroundColor Yellow
} else {
    Write-Host "  [成功] 磁盘空间充足" -ForegroundColor Green
}