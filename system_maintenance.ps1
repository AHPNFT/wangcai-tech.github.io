# 系统维护自动化脚本
# 功能：30分钟重启一次 + 10分钟移动鼠标防止休眠

param(
    [int]$RestartInterval = 1800,  # 30分钟 = 1800秒
    [int]$MouseMoveInterval = 600, # 10分钟 = 600秒
    [switch]$TestMode = $false     # 测试模式，不实际重启
)

# 记录日志函数
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path "system_maintenance.log" -Value $logMessage
}

# 移动鼠标函数
function Move-Mouse {
    $signature = @'
    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int x, int y);
'@
    Add-Type -MemberDefinition $signature -Name Win32Mouse -Namespace Win32Functions
    $screenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
    $screenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height
    
    # 随机移动鼠标到不同位置
    $x = Get-Random -Minimum 100 -Maximum ($screenWidth - 100)
    $y = Get-Random -Minimum 100 -Maximum ($screenHeight - 100)
    
    [Win32Functions.Win32Mouse]::SetCursorPos($x, $y)
    Write-Log "鼠标移动到位置: ($x, $y)"
}

# 重启系统函数
function Restart-System {
    if ($TestMode) {
        Write-Log "测试模式：模拟重启系统"
        return
    }
    
    Write-Log "正在重启系统..."
    
    # 保存当前工作状态
    $restartTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $restartInfo = @{
        LastRestart = $restartTime
        NextRestart = (Get-Date).AddSeconds($RestartInterval).ToString("yyyy-MM-dd HH:mm:ss")
    } | ConvertTo-Json
    Set-Content -Path "restart_info.json" -Value $restartInfo
    
    # 执行重启
    Restart-Computer -Force
}

# 主循环
Write-Log "系统维护自动化脚本启动"
Write-Log "配置：重启间隔 $RestartInterval 秒，鼠标移动间隔 $MouseMoveInterval 秒"

$lastRestartTime = Get-Date
$lastMouseMoveTime = Get-Date

try {
    while ($true) {
        $currentTime = Get-Date
        
        # 检查是否需要移动鼠标
        $mouseElapsed = ($currentTime - $lastMouseMoveTime).TotalSeconds
        if ($mouseElapsed -ge $MouseMoveInterval) {
            Move-Mouse
            $lastMouseMoveTime = $currentTime
        }
        
        # 检查是否需要重启
        $restartElapsed = ($currentTime - $lastRestartTime).TotalSeconds
        if ($restartElapsed -ge $RestartInterval) {
            Write-Log "达到重启时间间隔，准备重启..."
            Restart-System
            $lastRestartTime = $currentTime
        }
        
        # 显示状态
        $nextMouseMove = $MouseMoveInterval - $mouseElapsed
        $nextRestart = $RestartInterval - $restartElapsed
        
        if ((Get-Date -Format "ss") -eq "00") {  # 每分钟显示一次状态
            Write-Log "状态：下次鼠标移动 $([math]::Round($nextMouseMove)) 秒后，下次重启 $([math]::Round($nextRestart)) 秒后"
        }
        
        # 等待1秒
        Start-Sleep -Seconds 1
    }
} catch {
    Write-Log "脚本出错：$_"
    Write-Log "脚本已停止"
}