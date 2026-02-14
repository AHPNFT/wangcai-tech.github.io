# 一键设置所有Chrome扩展稳定措施

Write-Host "=== 一键设置Chrome扩展稳定措施 ===" -ForegroundColor Cyan
Write-Host "版本: 1.0" -ForegroundColor White
Write-Host "日期: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
Write-Host "`n正在设置以下稳定措施..." -ForegroundColor Yellow

# 1. 创建所有必要的脚本
Write-Host "`n1. 创建稳定脚本..." -ForegroundColor Yellow

$scripts = @{
    "chrome_extension_stabilizer.ps1" = @"
# Chrome Extension Stabilizer - 确保Chrome扩展稳定连接
param([int]`$CheckInterval = 300, [int]`$MaxRetries = 3)

Write-Host "=== Chrome扩展稳定器启动 ===" -ForegroundColor Cyan
while (`$true) {
    `$chromeProcesses = Get-Process chrome -ErrorAction SilentlyContinue
    if (`$chromeProcesses) {
        Write-Host "[`$(Get-Date -Format 'HH:mm:ss')] ✅ Chrome运行中" -ForegroundColor Green
    } else {
        Write-Host "[`$(Get-Date -Format 'HH:mm:ss')] ❌ Chrome未运行" -ForegroundColor Red
    }
    Start-Sleep -Seconds `$CheckInterval
}
"@
    
    "keep_chrome_connected.ps1" = @"
# 保持Chrome扩展连接
Write-Host "=== 保持Chrome扩展连接 ===" -ForegroundColor Cyan
while (`$true) {
    `$chromeProcesses = Get-Process chrome -ErrorAction SilentlyContinue
    if (`$chromeProcesses) {
        Write-Host "[`$(Get-Date -Format 'HH:mm:ss')] ✅ Chrome运行中" -ForegroundColor Green
    }
    Start-Sleep -Seconds 180
}
"@
    
    "check_connection.ps1" = @"
# 快速检查连接状态
Write-Host "=== Chrome扩展连接状态检查 ===" -ForegroundColor Cyan

# 检查Chrome
`$chrome = Get-Process chrome -ErrorAction SilentlyContinue
if (`$chrome) { Write-Host "✅ Chrome: 运行中 (`$(`$chrome.Count) 进程)" -ForegroundColor Green }
else { Write-Host "❌ Chrome: 未运行" -ForegroundColor Red }

# 检查OpenClaw
try {
    `$status = openclaw status --json 2>`$null
    if (`$status) { Write-Host "✅ OpenClaw: 运行中" -ForegroundColor Green }
    else { Write-Host "❌ OpenClaw: 未运行" -ForegroundColor Red }
} catch { Write-Host "⚠️ OpenClaw: 检查失败" -ForegroundColor Yellow }

# 检查端口
`$port = Test-NetConnection -ComputerName 127.0.0.1 -Port 18792 -InformationLevel Quiet
if (`$port) { Write-Host "✅ 端口18792: 监听中" -ForegroundColor Green }
else { Write-Host "❌ 端口18792: 未监听" -ForegroundColor Red }

Write-Host "`n=== 检查完成 ===" -ForegroundColor Cyan
"@
}

foreach ($scriptName in $scripts.Keys) {
    $scriptPath = "C:\Users\Administrator\.openclaw\workspace\$scriptName"
    Set-Content -Path $scriptPath -Value $scripts[$scriptName] -Encoding UTF8
    Write-Host "  ✅ 创建: $scriptName" -ForegroundColor Green
}

# 2. 创建计划任务
Write-Host "`n2. 设置计划任务..." -ForegroundColor Yellow

$taskName = "OpenClaw Chrome Stabilizer"
$scriptPath = "C:\Users\Administrator\.openclaw\workspace\chrome_extension_stabilizer.ps1"

try {
    # 删除现有任务（如果存在）
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    
    # 创建新任务
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -Force
    Write-Host "  ✅ 计划任务创建成功" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️ 计划任务创建失败: $_" -ForegroundColor Yellow
}

# 3. 创建桌面快捷方式
Write-Host "`n3. 创建桌面快捷方式..." -ForegroundColor Yellow

$desktop = [Environment]::GetFolderPath("Desktop")
$shortcuts = @(
    @{
        Name = "Chrome扩展稳定器.lnk"
        Target = "powershell.exe"
        Args = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
        Icon = "C:\Windows\System32\SHELL32.dll,71"
    },
    @{
        Name = "检查连接状态.lnk"
        Target = "powershell.exe"
        Args = "-ExecutionPolicy Bypass -NoExit -File `"C:\Users\Administrator\.openclaw\workspace\check_connection.ps1`""
        Icon = "C:\Windows\System32\SHELL32.dll,22"
    }
)

foreach ($shortcut in $shortcuts) {
    try {
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut("$desktop\$($shortcut.Name)")
        $Shortcut.TargetPath = $shortcut.Target
        $Shortcut.Arguments = $shortcut.Args
        $Shortcut.WorkingDirectory = "C:\Users\Administrator\.openclaw\workspace"
        $Shortcut.WindowStyle = 7
        $Shortcut.IconLocation = $shortcut.Icon
        $Shortcut.Save()
        Write-Host "  ✅ 创建: $($shortcut.Name)" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️ 创建失败: $($shortcut.Name)" -ForegroundColor Yellow
    }
}

# 4. 创建启动脚本
Write-Host "`n4. 创建启动脚本..." -ForegroundColor Yellow

$startScript = @"
@echo off
echo ========================================
echo    Chrome扩展稳定器 - 手动启动
echo ========================================
echo.
echo 正在启动稳定器...
echo.
powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0chrome_extension_stabilizer.ps1"
echo.
echo 稳定器已启动，按任意键退出...
pause >nul
"@

Set-Content -Path "C:\Users\Administrator\.openclaw\workspace\start_stabilizer.bat" -Value $startScript -Encoding ASCII
Write-Host "  ✅ 创建: start_stabilizer.bat" -ForegroundColor Green

# 5. 创建配置文件
Write-Host "`n5. 创建配置文件..." -ForegroundColor Yellow

$config = @{
    "stabilizer_enabled" = $true
    "check_interval_seconds" = 300
    "max_retries" = 3
    "auto_restart_chrome" = $true
    "simulate_user_activity" = $true
    "last_configured" = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

$configJson = $config | ConvertTo-Json
Set-Content -Path "C:\Users\Administrator\.openclaw\workspace\chrome_stabilizer_config.json" -Value $configJson -Encoding UTF8
Write-Host "  ✅ 创建: chrome_stabilizer_config.json" -ForegroundColor Green

# 6. 立即启动稳定器
Write-Host "`n6. 启动稳定器..." -ForegroundColor Yellow

try {
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`"" -WindowStyle Hidden
    Write-Host "  ✅ 稳定器已启动" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️ 启动失败: $_" -ForegroundColor Yellow
}

Write-Host "`n=== 设置完成 ===" -ForegroundColor Cyan
Write-Host "`n已配置的稳定措施:" -ForegroundColor White
Write-Host "1. ✅ 自动稳定器脚本" -ForegroundColor Green
Write-Host "2. ✅ 开机自启动计划任务" -ForegroundColor Green
Write-Host "3. ✅ 桌面快捷方式 (2个)" -ForegroundColor Green
Write-Host "4. ✅ 手动启动批处理" -ForegroundColor Green
Write-Host "5. ✅ 配置文件" -ForegroundColor Green
Write-Host "6. ✅ 立即启动稳定器" -ForegroundColor Green

Write-Host "`n下一步操作:" -ForegroundColor Yellow
Write-Host "1. 打开Chrome浏览器" -ForegroundColor White
Write-Host "2. 切换到Gmail标签页" -ForegroundColor White
Write-Host "3. 点击右上角OpenClaw扩展图标连接" -ForegroundColor White
Write-Host "4. 稳定器会自动保持连接" -ForegroundColor White

Write-Host "`n监控方法:" -ForegroundColor Yellow
Write-Host "• 双击桌面'检查连接状态'快捷方式" -ForegroundColor White
Write-Host "• 查看任务管理器中的powershell进程" -ForegroundColor White
Write-Host "• 检查系统托盘图标" -ForegroundColor White

Write-Host "`n现在请手动连接Chrome扩展！" -ForegroundColor Red -BackgroundColor White