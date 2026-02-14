# 简单维护脚本 - 30分钟重启 + 10分钟鼠标移动

# 移动鼠标函数
function Move-Mouse {
    Add-Type -AssemblyName System.Windows.Forms
    $screenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
    $screenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height
    
    # 随机移动鼠标
    $x = Get-Random -Minimum 100 -Maximum ($screenWidth - 100)
    $y = Get-Random -Minimum 100 -Maximum ($screenHeight - 100)
    
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] 鼠标移动到: ($x, $y)"
}

# 主循环
Write-Host "系统维护脚本启动"
Write-Host "配置: 30分钟重启一次, 10分钟移动鼠标"
Write-Host "按 Ctrl+C 停止脚本"

$lastRestart = Get-Date
$lastMouseMove = Get-Date
$restartCount = 0

try {
    while ($true) {
        $now = Get-Date
        
        # 检查鼠标移动
        $mouseElapsed = ($now - $lastMouseMove).TotalSeconds
        if ($mouseElapsed -ge 600) {  # 10分钟
            Move-Mouse
            $lastMouseMove = $now
        }
        
        # 检查重启
        $restartElapsed = ($now - $lastRestart).TotalSeconds
        if ($restartElapsed -ge 1800) {  # 30分钟
            $restartCount++
            Write-Host "执行第 $restartCount 次重启..."
            
            # 保存重启信息
            $info = @{
                Count = $restartCount
                LastRestart = $now.ToString("yyyy-MM-dd HH:mm:ss")
                NextRestart = $now.AddSeconds(1800).ToString("yyyy-MM-dd HH:mm:ss")
            } | ConvertTo-Json
            Set-Content -Path "restart_log.json" -Value $info
            
            # 重启系统
            Restart-Computer -Force
            $lastRestart = $now
        }
        
        # 显示状态
        if ((Get-Date -Format "ss") -eq "00") {
            $nextMouse = 600 - $mouseElapsed
            $nextRestart = 1800 - $restartElapsed
            Write-Host "状态: 鼠标$([math]::Round($nextMouse))秒, 重启$([math]::Round($nextRestart))秒"
        }
        
        Start-Sleep -Seconds 1
    }
} catch {
    Write-Host "脚本停止: $_"
}