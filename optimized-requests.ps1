# 优化请求函数 - 避免速率限制和卡死
function Invoke-OptimizedRequest {
    param(
        [string]$Url,
        [string]$Method = "Get",
        [object]$Body = $null,
        [hashtable]$Headers = @{},
        [int]$MinDelay = 1000,
        [int]$MaxDelay = 3000,
        [int]$MaxRetries = 3
    )
    
    # 添加随机延迟
    $delay = Get-Random -Minimum $MinDelay -Maximum $MaxDelay
    Write-Host "等待 $delay ms 以避免速率限制..."
    Start-Sleep -Milliseconds $delay
    
    $retryCount = 0
    while ($retryCount -lt $MaxRetries) {
        try {
            $params = @{
                Uri = $Url
                Method = $Method
                Headers = $Headers
                ContentType = "application/json"
                TimeoutSec = 30
            }
            
            if ($Body) {
                if ($Body -is [string]) {
                    $params.Body = $Body
                } else {
                    $params.Body = $Body | ConvertTo-Json -Compress
                }
            }
            
            $response = Invoke-RestMethod @params
            return $response
            
        } catch {
            $retryCount++
            Write-Warning "请求失败 (尝试 $retryCount/$MaxRetries): $($_.Exception.Message)"
            
            if ($retryCount -ge $MaxRetries) {
                Write-Error "达到最大重试次数，请求失败"
                throw
            }
            
            # 指数退避延迟
            $backoffDelay = [math]::Pow(2, $retryCount) * 1000
            Write-Host "等待 $backoffDelay ms 后重试..."
            Start-Sleep -Milliseconds $backoffDelay
        }
    }
}

# Moltbook专用请求函数
function Invoke-MoltbookRequest {
    param(
        [string]$Endpoint,
        [string]$Method = "Get",
        [object]$Data = $null
    )
    
    $apiKey = "moltbook_sk_IR97ZWzCmbAwLV8gZlDijJczhlk1AIVV"
    $baseUrl = "https://www.moltbook.com/api/v1"
    
    $headers = @{
        Authorization = "Bearer $apiKey"
    }
    
    return Invoke-OptimizedRequest -Url "$baseUrl$Endpoint" -Method $Method -Body $Data -Headers $headers -MinDelay 2000 -MaxDelay 5000
}

# 系统健康检查函数
function Test-SystemHealth {
    Write-Host "`n=== 系统健康检查 ==="
    
    # 检查CPU使用率
    $cpu = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue
    if ($cpu) {
        $cpuValue = $cpu.CounterSamples.CookedValue
        Write-Host "CPU使用率: $cpuValue%"
    }
    
    # 检查内存使用率
    $mem = Get-Counter '\Memory\% Committed Bytes In Use' -ErrorAction SilentlyContinue
    if ($mem) {
        $memValue = $mem.CounterSamples.CookedValue
        Write-Host "内存使用率: $memValue%"
    }
    
    # 检查OpenClaw进程
    $openclawProcesses = Get-Process -Name node -ErrorAction SilentlyContinue | Where-Object {$_.Path -like "*openclaw*"}
    Write-Host "OpenClaw进程数: $($openclawProcesses.Count)"
    
    # 检查网络连接
    try {
        $ping = Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet
        Write-Host "网络连接: $(if($ping){'正常'}else{'异常'})"
    } catch {
        Write-Host "网络连接: 测试失败"
    }
    
    Write-Host "=== 检查完成 ===`n"
}

# 导出函数
Export-ModuleMember -Function Invoke-OptimizedRequest, Invoke-MoltbookRequest, Test-SystemHealth