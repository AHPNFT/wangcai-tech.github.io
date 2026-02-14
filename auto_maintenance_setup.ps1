# 自动化维护设置脚本
# 设置30分钟重启 + 10分钟鼠标移动

Write-Host "=== 系统自动化维护设置 ==="
Write-Host "1. 创建计划任务"
Write-Host "2. 设置电源选项（永不休眠）"
Write-Host "3. 启动维护脚本"
Write-Host "=========================="

# 1. 设置电源选项 - 永不休眠
Write-Host "设置电源选项..."
powercfg -change -standby-timeout-ac 0
powercfg -change -hibernate-timeout-ac 0
powercfg -change -monitor-timeout-ac 0
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c  # 高性能计划

Write-Host "电源选项设置完成：永不休眠"

# 2. 创建计划任务（鼠标移动）
$taskName = "MouseMovePreventSleep"
$taskDescription = "每10分钟移动鼠标防止系统休眠"
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -File `"$PWD\quick_mouse_move.ps1`""
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 10)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

Register-ScheduledTask -TaskName $taskName -Description $taskDescription -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -Force
Write-Host "鼠标移动计划任务创建完成"

# 3. 创建计划任务（系统重启）
$restartTaskName = "SystemRestart30Min"
$restartDescription = "每30分钟重启系统一次"
$restartAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -File `"$PWD\scheduled_restart.ps1`""
$restartTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 30)

Register-ScheduledTask -TaskName $restartTaskName -Description $restartDescription -Action $restartAction -Trigger $restartTrigger -Settings $settings -RunLevel Highest -Force
Write-Host "系统重启计划任务创建完成"

# 4. 启动OpenClaw维护服务
Write-Host "启动OpenClaw维护服务..."
Start-Process powershell -ArgumentList "-WindowStyle Hidden -File `"$PWD\system_maintenance.ps1`"" -NoNewWindow

Write-Host "`n=== 设置完成 ==="
Write-Host "✅ 电源选项：永不休眠"
Write-Host "✅ 鼠标移动：每10分钟执行"
Write-Host "✅ 系统重启：每30分钟执行"
Write-Host "✅ OpenClaw维护服务已启动"
Write-Host "`n系统将在后台自动运行维护任务"