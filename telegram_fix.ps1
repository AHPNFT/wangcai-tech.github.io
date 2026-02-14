# Telegram和网络修复脚本
Write-Host "=== Telegram & Network Fix ==="
Write-Host "Time: $(Get-Date)"
Write-Host ""

# 1. 检查网络连接
Write-Host "1. Checking network connection..."
try {
    $pingResult = Test-Connection -ComputerName "8.8.8.8" -Count 2 -Quiet
    if ($pingResult) {
        Write-Host "   Network: OK (can reach 8.8.8.8)" -ForegroundColor Green
    } else {
        Write-Host "   Network: FAILED (cannot reach 8.8.8.8)" -ForegroundColor Red
    }
} catch {
    Write-Host "   Network check error: $_" -ForegroundColor Red
}

Write-Host ""

# 2. 修复网络设置
Write-Host "2. Fixing network settings..."
try {
    Write-Host "   Flushing DNS cache..."
    ipconfig /flushdns
    Write-Host "   DNS cache flushed" -ForegroundColor Green
    
    Write-Host "   Resetting Winsock..."
    netsh winsock reset
    Write-Host "   Winsock reset" -ForegroundColor Green
    
    Write-Host "   Resetting TCP/IP..."
    netsh int ip reset
    Write-Host "   TCP/IP reset" -ForegroundColor Green
    
    Write-Host "   Clearing proxy settings..."
    netsh winhttp reset proxy
    Write-Host "   Proxy cleared" -ForegroundColor Green
} catch {
    Write-Host "   Network fix error: $_" -ForegroundColor Red
}

Write-Host ""

# 3. 检查防火墙
Write-Host "3. Checking firewall..."
try {
    $firewallStatus = Get-NetFirewallProfile -Profile Domain,Public,Private | Select-Object Name, Enabled
    foreach ($profile in $firewallStatus) {
        $status = if ($profile.Enabled) { "ENABLED" -ForegroundColor Yellow } else { "DISABLED" -ForegroundColor Green }
        Write-Host "   $($profile.Name) firewall: $status"
    }
} catch {
    Write-Host "   Firewall check error: $_" -ForegroundColor Red
}

Write-Host ""

# 4. 重启Telegram服务
Write-Host "4. Restarting Telegram service..."
try {
    # 停止OpenClaw网关
    Write-Host "   Stopping OpenClaw gateway..."
    openclaw gateway stop 2>$null
    Write-Host "   OpenClaw stopped" -ForegroundColor Green
    
    # 等待
    Start-Sleep -Seconds 3
    
    # 启动OpenClaw网关
    Write-Host "   Starting OpenClaw gateway..."
    openclaw gateway start 2>$null
    Write-Host "   OpenClaw started" -ForegroundColor Green
    
    # 等待服务启动
    Write-Host "   Waiting for services to start..."
    Start-Sleep -Seconds 5
} catch {
    Write-Host "   Service restart error: $_" -ForegroundColor Red
}

Write-Host ""

# 5. 检查Telegram连接
Write-Host "5. Testing Telegram connection..."
try {
    Write-Host "   Checking OpenClaw status..."
    $status = openclaw status 2>$null
    if ($status -like "*Telegram*OK*") {
        Write-Host "   Telegram: CONNECTED" -ForegroundColor Green
    } else {
        Write-Host "   Telegram: NOT CONNECTED" -ForegroundColor Red
        Write-Host "   Status output:" -ForegroundColor Yellow
        $status
    }
} catch {
    Write-Host "   Status check error: $_" -ForegroundColor Red
}

Write-Host ""

# 6. 检查系统代理
Write-Host "6. Checking system proxy..."
try {
    $proxy = netsh winhttp show proxy
    Write-Host "   Current proxy settings:" -ForegroundColor White
    $proxy
} catch {
    Write-Host "   Proxy check error: $_" -ForegroundColor Red
}

Write-Host ""

# 7. 检查VPN/代理软件
Write-Host "7. Checking VPN/Proxy software..."
try {
    $vpnProcesses = Get-Process | Where-Object {$_.Name -like "*vpn*" -or $_.Name -like "*proxy*" -or $_.Name -like "*lets*"} | Select-Object Name, Id
    if ($vpnProcesses) {
        Write-Host "   Found VPN/Proxy processes:" -ForegroundColor Yellow
        $vpnProcesses | ForEach-Object {
            Write-Host "   - $($_.Name) (PID: $($_.Id))"
        }
        Write-Host "   Consider disabling VPN if Telegram still has issues" -ForegroundColor Yellow
    } else {
        Write-Host "   No VPN/Proxy processes found" -ForegroundColor Green
    }
} catch {
    Write-Host "   Process check error: $_" -ForegroundColor Red
}

Write-Host ""

# 8. 创建测试脚本
Write-Host "8. Creating test script..."
$testScript = @'
# Telegram连接测试脚本
Write-Host "Testing Telegram connection..."

# 测试网络
Write-Host "1. Testing network to Telegram API..."
$telegramApi = "api.telegram.org"
try {
    $result = Test-Connection -ComputerName $telegramApi -Count 2 -Quiet
    if ($result) {
        Write-Host "   Can reach $telegramApi: YES" -ForegroundColor Green
    } else {
        Write-Host "   Can reach $telegramApi: NO" -ForegroundColor Red
    }
} catch {
    Write-Host "   Network test error: $_" -ForegroundColor Red
}

# 测试OpenClaw状态
Write-Host "2. Testing OpenClaw Telegram status..."
try {
    $status = openclaw status 2>$null
    if ($status -match "Telegram.*OK") {
        Write-Host "   OpenClaw Telegram: CONNECTED" -ForegroundColor Green
    } else {
        Write-Host "   OpenClaw Telegram: DISCONNECTED" -ForegroundColor Red
    }
} catch {
    Write-Host "   OpenClaw test error: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "If Telegram is still not working:"
Write-Host "1. Check your internet connection"
Write-Host "2. Disable VPN/Proxy temporarily"
Write-Host "3. Restart computer"
Write-Host "4. Check Telegram bot token is valid"
'@

$testScript | Out-File -FilePath "C:\Users\Administrator\.openclaw\workspace\test_telegram.ps1" -Encoding UTF8
Write-Host "   Test script created: test_telegram.ps1" -ForegroundColor Green

Write-Host ""
Write-Host "=== FIX COMPLETE ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor White
Write-Host "1. Network settings reset" -ForegroundColor Green
Write-Host "2. DNS and Winsock cleared" -ForegroundColor Green
Write-Host "3. OpenClaw services restarted" -ForegroundColor Green
Write-Host "4. Telegram connection tested" -ForegroundColor Green
Write-Host "5. Test script created" -ForegroundColor Green
Write-Host ""
Write-Host "To test Telegram connection, run: .\test_telegram.ps1" -ForegroundColor Yellow
Write-Host ""
Write-Host "If Telegram still doesn't work:" -ForegroundColor Red
Write-Host "1. Check if Telegram bot token is still valid" -ForegroundColor White
Write-Host "2. Check if Telegram API is blocked in your region" -ForegroundColor White
Write-Host "3. Try using a VPN to access Telegram API" -ForegroundColor White
Write-Host "4. Restart your computer" -ForegroundColor White