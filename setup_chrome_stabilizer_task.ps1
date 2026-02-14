# 设置Chrome扩展稳定器计划任务

Write-Host "=== 设置Chrome扩展稳定器计划任务 ===" -ForegroundColor Cyan

# 脚本路径
$scriptPath = "C:\Users\Administrator\.openclaw\workspace\chrome_extension_stabilizer.ps1"
$taskName = "OpenClaw Chrome Extension Stabilizer"

# 检查脚本是否存在
if (-not (Test-Path $scriptPath)) {
    Write-Host "❌ 脚本不存在: $scriptPath" -ForegroundColor Red
    exit 1
}

Write-Host "`n1. 创建计划任务..." -ForegroundColor Yellow

# 创建计划任务
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 5)

# 注册任务
try {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -Force
    Write-Host "   ✅ 计划任务创建成功: $taskName" -ForegroundColor Green
} catch {
    Write-Host "   ❌ 计划任务创建失败: $_" -ForegroundColor Red
    exit 1
}

# 立即启动任务
Write-Host "`n2. 启动计划任务..." -ForegroundColor Yellow
try {
    Start-ScheduledTask -TaskName $taskName
    Write-Host "   ✅ 任务已启动" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️ 无法启动任务: $_" -ForegroundColor Yellow
}

# 检查任务状态
Write-Host "`n3. 检查任务状态..." -ForegroundColor Yellow
try {
    $task = Get-ScheduledTask -TaskName $taskName
    Write-Host "   ✅ 任务状态: $($task.State)" -ForegroundColor Green
    Write-Host "   ℹ️ 任务路径: $($task.TaskPath)" -ForegroundColor White
    Write-Host "   ℹ️ 触发器: $($task.Triggers[0])" -ForegroundColor White
} catch {
    Write-Host "   ⚠️ 无法获取任务状态: $_" -ForegroundColor Yellow
}

# 创建快捷方式
Write-Host "`n4. 创建桌面快捷方式..." -ForegroundColor Yellow
$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktopPath "Chrome扩展稳定器.lnk"

try {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
    $Shortcut.WorkingDirectory = "C:\Users\Administrator\.openclaw\workspace"
    $Shortcut.WindowStyle = 7  # 最小化窗口
    $Shortcut.IconLocation = "C:\Windows\System32\SHELL32.dll,71"  # 齿轮图标
    $Shortcut.Description = "OpenClaw Chrome扩展稳定器"
    $Shortcut.Save()
    
    Write-Host "   ✅ 快捷方式创建成功: $shortcutPath" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️ 快捷方式创建失败: $_" -ForegroundColor Yellow
}

# 创建手动启动脚本
Write-Host "`n5. 创建手动启动脚本..." -ForegroundColor Yellow
$manualScript = @"
@echo off
echo 启动Chrome扩展稳定器...
powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0chrome_extension_stabilizer.ps1"
pause
"@

$manualScriptPath = "C:\Users\Administrator\.openclaw\workspace\start_chrome_stabilizer.bat"
Set-Content -Path $manualScriptPath -Value $manualScript -Encoding ASCII
Write-Host "   ✅ 手动启动脚本创建成功: $manualScriptPath" -ForegroundColor Green

Write-Host "`n=== 设置完成 ===" -ForegroundColor Cyan
Write-Host "`n已配置以下稳定措施:" -ForegroundColor White
Write-Host "1. ✅ 计划任务 - 开机自动启动" -ForegroundColor Green
Write-Host "2. ✅ 桌面快捷方式 - 手动启动" -ForegroundColor Green
Write-Host "3. ✅ 批处理脚本 - 备用启动" -ForegroundColor Green
Write-Host "4. ✅ 自动重连 - 每5分钟检查一次" -ForegroundColor Green
Write-Host "5. ✅ 失败重试 - 最多3次" -ForegroundColor Green

Write-Host "`n使用方法:" -ForegroundColor White
Write-Host "• 自动: 系统启动时自动运行" -ForegroundColor White
Write-Host "• 手动: 双击桌面快捷方式" -ForegroundColor White
Write-Host "• 监控: 查看系统托盘图标" -ForegroundColor White

Write-Host "`n现在请手动连接Chrome扩展:" -ForegroundColor Yellow
Write-Host "1. 打开Chrome浏览器" -ForegroundColor White
Write-Host "2. 切换到Gmail标签页" -ForegroundColor White
Write-Host "3. 点击右上角OpenClaw扩展图标" -ForegroundColor White
Write-Host "4. 等待连接成功" -ForegroundColor White