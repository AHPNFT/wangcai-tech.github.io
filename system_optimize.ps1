# 系统优化脚本
Write-Host "=== 系统优化开始 ===" -ForegroundColor Green

# 1. 清理临时文件
Write-Host "1. 清理临时文件..." -ForegroundColor Yellow
Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:WINDIR\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# 2. 清理预取文件
Write-Host "2. 清理预取文件..." -ForegroundColor Yellow
Remove-Item "C:\Windows\Prefetch\*" -Force -ErrorAction SilentlyContinue

# 3. 清理DNS缓存
Write-Host "3. 清理DNS缓存..." -ForegroundColor Yellow
ipconfig /flushdns | Out-Null

# 4. 重启Windows资源管理器（不重启系统）
Write-Host "4. 优化资源管理器..." -ForegroundColor Yellow
Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
Start-Process "explorer.exe"

# 5. 优化电源设置（确保永远不休眠）
Write-Host "5. 优化电源设置..." -ForegroundColor Yellow
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
powercfg /change hibernate-timeout-ac 0
powercfg /change hibernate-timeout-dc 0
powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 0
powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 0
powercfg /setactive SCHEME_CURRENT

# 6. 显示当前系统状态
Write-Host "6. 显示系统状态..." -ForegroundColor Yellow
Get-Counter "\Processor(_Total)\% Processor Time" | Select-Object -ExpandProperty CounterSamples | Select-Object -ExpandProperty CookedValue | ForEach-Object { Write-Host "CPU使用率: $_%" }
Get-Counter "\Memory\Available MBytes" | Select-Object -ExpandProperty CounterSamples | Select-Object -ExpandProperty CookedValue | ForEach-Object { Write-Host "可用内存: $_ MB" }

Write-Host "=== 系统优化完成 ===" -ForegroundColor Green
Write-Host "系统已优化，现在应该更加流畅。" -ForegroundColor Cyan