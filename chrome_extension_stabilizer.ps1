# Chrome Extension Stabilizer - 确保Chrome扩展稳定连接
# 这个脚本会定期检查并重新连接Chrome扩展

param(
    [int]$CheckInterval = 300,  # 检查间隔（秒），默认5分钟
    [int]$MaxRetries = 3        # 最大重试次数
)

Write-Host "=== Chrome扩展稳定器启动 ===" -ForegroundColor Cyan
Write-Host "检查间隔: $CheckInterval 秒" -ForegroundColor White
Write-Host "最大重试次数: $MaxRetries" -ForegroundColor White
Write-Host "按 Ctrl+C 停止" -ForegroundColor Yellow

function Test-ChromeExtensionConnection {
    Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] 检查Chrome扩展连接..." -ForegroundColor Gray
    
    # 检查Chrome进程
    $chromeProcesses = Get-Process chrome -ErrorAction SilentlyContinue
    if (-not $chromeProcesses) {
        Write-Host "  ❌ Chrome未运行" -ForegroundColor Red
        return $false
    }
    
    # 检查OpenClaw网关
    try {
        $gatewayStatus = openclaw status --json 2>$null
        if (-not $gatewayStatus) {
            Write-Host "  ❌ OpenClaw网关未运行" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "  ⚠️ 无法检查OpenClaw状态" -ForegroundColor Yellow
        return $false
    }
    
    # 检查浏览器控制端口
    $portCheck = Test-NetConnection -ComputerName 127.0.0.1 -Port 18792 -InformationLevel Quiet
    if (-not $portCheck) {
        Write-Host "  ❌ 浏览器控制端口未监听" -ForegroundColor Red
        return $false
    }
    
    Write-Host "  ✅ 基础组件正常" -ForegroundColor Green
    return $true
}

function Ensure-GmailTabOpen {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 确保Gmail标签页打开..." -ForegroundColor Gray
    
    # 检查Chrome是否运行
    $chromeProcesses = Get-Process chrome -ErrorAction SilentlyContinue
    if (-not $chromeProcesses) {
        Write-Host "  ⚠️ Chrome未运行，启动Chrome..." -ForegroundColor Yellow
        Start-Process "chrome.exe" "https://mail.google.com"
        Start-Sleep -Seconds 5
    }
    
    # 尝试通过命令行打开Gmail
    Write-Host "  ℹ️ 确保Gmail标签页已打开" -ForegroundColor White
    return $true
}

function Restart-OpenClawGateway {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 重启OpenClaw网关..." -ForegroundColor Gray
    
    try {
        Write-Host "  ℹ️ 停止OpenClaw网关..." -ForegroundColor White
        openclaw gateway stop 2>$null
        
        Start-Sleep -Seconds 2
        
        Write-Host "  ℹ️ 启动OpenClaw网关..." -ForegroundColor White
        openclaw gateway start 2>$null
        
        Start-Sleep -Seconds 5
        
        Write-Host "  ✅ 网关重启完成" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  ❌ 网关重启失败: $_" -ForegroundColor Red
        return $false
    }
}

# 主循环
$retryCount = 0
while ($true) {
    $connectionOk = Test-ChromeExtensionConnection
    
    if (-not $connectionOk) {
        Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] 连接异常，尝试修复..." -ForegroundColor Yellow
        
        # 确保Gmail标签页打开
        Ensure-GmailTabOpen
        
        # 重启OpenClaw网关
        $restartSuccess = Restart-OpenClawGateway
        
        if ($restartSuccess) {
            Write-Host "  ✅ 修复完成，等待连接..." -ForegroundColor Green
            $retryCount = 0
        } else {
            $retryCount++
            Write-Host "  ⚠️ 修复失败，重试次数: $retryCount/$MaxRetries" -ForegroundColor Yellow
            
            if ($retryCount -ge $MaxRetries) {
                Write-Host "  ❌ 达到最大重试次数，等待下次检查..." -ForegroundColor Red
                $retryCount = 0
            }
        }
    } else {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 连接正常" -ForegroundColor Green
        $retryCount = 0
    }
    
    # 等待下次检查
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 等待 $CheckInterval 秒..." -ForegroundColor Gray
    Start-Sleep -Seconds $CheckInterval
}