# 保持Chrome扩展连接 - 简单版本
# 这个脚本会定期模拟用户活动，防止Chrome断开连接

Write-Host "=== 保持Chrome扩展连接 ===" -ForegroundColor Cyan
Write-Host "按 Ctrl+C 停止" -ForegroundColor Yellow

# 检查间隔（秒）
$checkInterval = 180  # 3分钟

# 模拟用户活动计数器
$activityCounter = 0

while ($true) {
    $currentTime = Get-Date -Format "HH:mm:ss"
    
    # 检查Chrome是否运行
    $chromeProcesses = Get-Process chrome -ErrorAction SilentlyContinue
    if ($chromeProcesses) {
        Write-Host "[$currentTime] ✅ Chrome正在运行 ($($chromeProcesses.Count) 进程)" -ForegroundColor Green
        
        # 每3次检查模拟一次用户活动
        if ($activityCounter % 3 -eq 0) {
            Write-Host "  🔄 模拟用户活动..." -ForegroundColor Gray
            
            # 方法1: 轻微移动鼠标（如果用户允许）
            try {
                Add-Type -AssemblyName System.Windows.Forms
                $originalPos = [System.Windows.Forms.Cursor]::Position
                [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point(($originalPos.X + 1), ($originalPos.Y + 1))
                Start-Sleep -Milliseconds 50
                [System.Windows.Forms.Cursor]::Position = $originalPos
                Write-Host "  ✅ 轻微移动鼠标完成" -ForegroundColor Green
            } catch {
                Write-Host "  ⚠️ 无法移动鼠标: $_" -ForegroundColor Yellow
            }
            
            # 方法2: 发送虚拟按键（Alt+Tab切换）
            try {
                Add-Type -AssemblyName System.Windows.Forms
                [System.Windows.Forms.SendKeys]::SendWait("%{TAB}")
                Start-Sleep -Milliseconds 100
                [System.Windows.Forms.SendKeys]::SendWait("%{TAB}")
                Write-Host "  ✅ 发送虚拟按键完成" -ForegroundColor Green
            } catch {
                Write-Host "  ⚠️ 无法发送按键: $_" -ForegroundColor Yellow
            }
        }
        
        $activityCounter++
    } else {
        Write-Host "[$currentTime] ❌ Chrome未运行" -ForegroundColor Red
        
        # 尝试启动Chrome
        Write-Host "  🔄 尝试启动Chrome..." -ForegroundColor Yellow
        try {
            Start-Process "chrome.exe" "https://mail.google.com"
            Write-Host "  ✅ Chrome已启动" -ForegroundColor Green
            Start-Sleep -Seconds 5
        } catch {
            Write-Host "  ❌ 无法启动Chrome: $_" -ForegroundColor Red
        }
    }
    
    # 检查OpenClaw网关
    try {
        $gatewayStatus = openclaw status --json 2>$null
        if ($gatewayStatus) {
            Write-Host "  ✅ OpenClaw网关正常" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️ OpenClaw网关异常" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ❌ 无法检查OpenClaw状态" -ForegroundColor Red
    }
    
    # 显示下次检查时间
    $nextCheck = (Get-Date).AddSeconds($checkInterval).ToString("HH:mm:ss")
    Write-Host "  ⏰ 下次检查: $nextCheck (等待 $checkInterval 秒...)" -ForegroundColor Gray
    Start-Sleep -Seconds $checkInterval
}