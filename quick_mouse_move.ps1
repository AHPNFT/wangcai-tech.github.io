# 快速鼠标移动脚本（防止休眠）
# 每10分钟移动一次鼠标

param(
    [int]$Interval = 600  # 10分钟 = 600秒
)

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
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] 鼠标移动到位置: ($x, $y)"
}

Write-Host "鼠标防休眠脚本启动 - 每 $Interval 秒移动一次鼠标"
Write-Host "按 Ctrl+C 停止脚本"

$lastMoveTime = Get-Date

try {
    while ($true) {
        $currentTime = Get-Date
        $elapsed = ($currentTime - $lastMoveTime).TotalSeconds
        
        if ($elapsed -ge $Interval) {
            Move-Mouse
            $lastMoveTime = $currentTime
        }
        
        # 显示倒计时
        $remaining = $Interval - $elapsed
        if ((Get-Date -Format "ss") -eq "00") {  # 每分钟显示一次
            Write-Host "下次移动: $([math]::Round($remaining)) 秒后"
        }
        
        Start-Sleep -Seconds 1
    }
} catch {
    Write-Host "脚本停止: $_"
}