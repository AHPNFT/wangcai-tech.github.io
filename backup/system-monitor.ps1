# 系统监控和自动恢复脚本
param(
    [int]$CheckInterval = 60,  # 检查间隔（秒）
    [int]$MaxCpu = 85,         # CPU阈值
    [int]$MaxMemory = 85,      # 内存阈值
    [string]$LogFile = "system-monitor.log"
)

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Add-Content -Path $LogFile -Value $logMessage
    Write-Host $logMessage
}

function Restart-OpenClaw {
    Write-Log "尝试重启OpenClaw..."
    try {
        # 停止OpenClaw进程
        Get-Process -Name node -ErrorAction SilentlyContinue | 
            Where-Object {$_.Path -like "*openclaw*"} | 
            Stop-Process -Force
        
        Start-Sleep -Seconds 5
        
        # 重新启动OpenClaw
        $openclawPath = "C:\Users\Administrator\scoop\persist\nodejs-lts\bin\node_modules\openclaw\bin\openclaw.js"
        if (Test-Path $openclawPath) {
            Start-Process node -ArgumentList $openclawPath, "gateway", "start" -WindowStyle Hidden
            Write-Log "✅ OpenClaw已重启"
            return $true
        } else {
            Write-Log "❌ 找不到OpenClaw路径"
            return $false
        }
    } catch {
        Write-Log "❌ 重启失败: $($_.Exception.Message)"
        return $false
    }
}

function Check-SystemHealth {
    $issues = @()
    
    # 检查CPU
    try {
        $cpu = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction Stop
        $cpuValue = [math]::Round($cpu.CounterSamples.CookedValue, 2)
        if ($cpuValue -gt $MaxCpu) {
            $issues += "CPU使用率过高: ${cpuValue}%"
        }
    } catch {
        $issues += "无法获取CPU信息"
    }
    
    # 检查内存
    try {
        $mem = Get-Counter '\Memory\% Committed Bytes In Use' -ErrorAction Stop
        $memValue = [math]::Round($mem.CounterSamples.CookedValue, 2)
        if ($memValue -gt $MaxMemory) {
            $issues += "内存使用率过高: ${memValue}%"
        }
    } catch {
        $issues += "无法获取内存信息"
    }
    
    # 检查OpenClaw进程
    $openclawProcesses = Get-Process -Name node -ErrorAction SilentlyContinue | 
        Where-Object {$_.Path -like "*openclaw*"}
    
    if ($openclawProcesses.Count -eq 0) {
        $issues += "OpenClaw进程未运行"
    } elseif ($openclawProcesses.Count -gt 2) {
        $issues += "检测到多个OpenClaw进程: $($openclawProcesses.Count)个"
    }
    
    # 检查磁盘空间
    try {
        $disk = Get-PSDrive C -ErrorAction Stop
        $freePercent = ($disk.Free / $disk.Used) * 100
        if ($freePercent -lt 10) {
            $issues += "C盘空间不足: 剩余$([math]::Round($freePercent, 2))%"
        }
    } catch {
        # 忽略磁盘检查错误
    }
    
    return @{
        Issues = $issues
        Cpu = $cpuValue
        Memory = $memValue
        OpenClawProcesses = $openclawProcesses.Count
    }
}

# 主监控循环
Write-Log "=== 系统监控启动 ==="
Write-Log "检查间隔: ${CheckInterval}秒"
Write-Log "CPU阈值: ${MaxCpu}%"
Write-Log "内存阈值: ${MaxMemory}%"

while ($true) {
    try {
        $health = Check-SystemHealth
        
        if ($health.Issues.Count -gt 0) {
            Write-Log "⚠️ 检测到问题:"
            foreach ($issue in $health.Issues) {
                Write-Log "  - $issue"
            }
            
            # 如果问题严重，尝试自动恢复
            if ($health.Issues -match "OpenClaw进程未运行" -or 
                $health.Cpu -gt 95 -or 
                $health.Memory -gt 95) {
                Write-Log "尝试自动恢复..."
                Restart-OpenClaw
            }
        } else {
            Write-Log "✅ 系统状态正常 (CPU: $($health.Cpu)%, 内存: $($health.Memory)%, 进程: $($health.OpenClawProcesses))"
        }
        
    } catch {
        Write-Log "❌ 监控检查失败: $($_.Exception.Message)"
    }
    
    # 等待下一次检查
    Start-Sleep -Seconds $CheckInterval
}