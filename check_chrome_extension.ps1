# 检查Chrome扩展状态的脚本
Write-Host "=== Chrome扩展状态检查 ===" -ForegroundColor Cyan

# 检查Chrome进程
Write-Host "`n1. Chrome进程状态:" -ForegroundColor Yellow
$chromeProcesses = Get-Process chrome -ErrorAction SilentlyContinue
if ($chromeProcesses) {
    Write-Host "   ✅ Chrome正在运行 ($($chromeProcesses.Count) 个进程)" -ForegroundColor Green
    Write-Host "   主进程PID: $($chromeProcesses[0].Id)" -ForegroundColor White
} else {
    Write-Host "   ❌ Chrome未运行" -ForegroundColor Red
}

# 检查OpenClaw网关
Write-Host "`n2. OpenClaw网关状态:" -ForegroundColor Yellow
try {
    $gatewayStatus = openclaw status --json 2>$null
    if ($gatewayStatus) {
        Write-Host "   ✅ OpenClaw网关正在运行" -ForegroundColor Green
    } else {
        Write-Host "   ❌ OpenClaw网关未运行" -ForegroundColor Red
    }
} catch {
    Write-Host "   ⚠️ 无法检查OpenClaw状态: $_" -ForegroundColor Yellow
}

# 检查浏览器控制端口
Write-Host "`n3. 浏览器控制端口(18792):" -ForegroundColor Yellow
$portCheck = Test-NetConnection -ComputerName 127.0.0.1 -Port 18792 -InformationLevel Quiet
if ($portCheck) {
    Write-Host "   ✅ 端口18792已监听" -ForegroundColor Green
} else {
    Write-Host "   ❌ 端口18792未监听" -ForegroundColor Red
}

# 检查Chrome扩展连接
Write-Host "`n4. Chrome扩展连接状态:" -ForegroundColor Yellow
Write-Host "   ⚠️ 需要手动检查:" -ForegroundColor Yellow
Write-Host "   1. 打开Chrome浏览器" -ForegroundColor White
Write-Host "   2. 导航到Gmail标签页" -ForegroundColor White
Write-Host "   3. 点击右上角的OpenClaw扩展图标" -ForegroundColor White
Write-Host "   4. 等待扩展连接到标签页" -ForegroundColor White

# 建议操作
Write-Host "`n=== 建议操作 ===" -ForegroundColor Cyan
Write-Host "1. 重启Chrome浏览器" -ForegroundColor White
Write-Host "2. 重新打开Gmail标签页" -ForegroundColor White
Write-Host "3. 点击OpenClaw扩展图标连接" -ForegroundColor White
Write-Host "4. 如果仍然失败，重启OpenClaw网关: openclaw gateway restart" -ForegroundColor White

Write-Host "`n=== 检查完成 ===" -ForegroundColor Cyan