# 定时重启脚本
# 每30分钟重启一次系统

param(
    [int]$Interval = 1800,  # 30分钟 = 1800秒
    [switch]$TestMode = $false
)

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path "scheduled_restart.log" -Value $logMessage
}

Write-Log "定时重启脚本启动 - 每 $Interval 秒重启一次系统"
Write-Log "当前时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

$startTime = Get-Date
$nextRestartTime = $startTime.AddSeconds($Interval)

Write-Log "下次重启时间: $($nextRestartTime.ToString('yyyy-MM-dd HH:mm:ss'))"

try {
    while ($true) {
        $currentTime = Get-Date
        
        if ($currentTime -ge $nextRestartTime) {
            Write-Log "达到重启时间，准备重启系统..."
            
            if (-not $TestMode) {
                # 保存重启信息
                $restartInfo = @{
                    LastRestart = $currentTime.ToString("yyyy-MM-dd HH:mm:ss")
                    NextRestart = $currentTime.AddSeconds($Interval).ToString("yyyy-MM-dd HH:mm:ss")
                    TotalRestarts = (Get-Content -Path "restart_count.txt" -ErrorAction SilentlyContinue | Select-Object -First 1) ?? 0
                } | ConvertTo-Json
                Set-Content -Path "restart_info.json" -Value $restartInfo
                
                # 增加重启计数
                $count = [int]($restartInfo.TotalRestarts) + 1
                Set-Content -Path "restart_count.txt" -Value $count
                
                Write-Log "执行第 $count 次重启..."
                
                # 重启系统
                Restart-Computer -Force
            } else {
                Write-Log "测试模式：模拟重启系统"
                $nextRestartTime = $currentTime.AddSeconds($Interval)
                Write-Log "下次重启时间: $($nextRestartTime.ToString('yyyy-MM-dd HH:mm:ss'))"
            }
        }
        
        # 显示倒计时
        $remaining = ($nextRestartTime - $currentTime).TotalSeconds
        if ((Get-Date -Format "ss") -eq "00") {  # 每分钟显示一次
            Write-Log "下次重启: $([math]::Round($remaining)) 秒后"
        }
        
        Start-Sleep -Seconds 1
    }
} catch {
    Write-Log "脚本出错: $_"
    Write-Log "脚本已停止"
}