# 脚本优化器 - 修复和优化自动化脚本
Write-Host "开始脚本优化..." -ForegroundColor Cyan

# 1. 检查当前目录的脚本文件
$scriptFiles = Get-ChildItem -Path . -Filter *.ps1 -File | Where-Object { $_.Name -notmatch 'optimizer|cleanup|monitor' }

if (-not $scriptFiles) {
    Write-Host "未找到需要优化的脚本文件" -ForegroundColor Yellow
    exit 0
}

Write-Host "找到 $($scriptFiles.Count) 个脚本文件:" -ForegroundColor White
$scriptFiles | ForEach-Object { Write-Host "  - $($_.Name)" }

# 2. 优化每个脚本
$optimizedCount = 0
foreach ($script in $scriptFiles) {
    Write-Host "`n优化脚本: $($script.Name)" -ForegroundColor Yellow
    
    try {
        # 读取原始内容
        $content = Get-Content $script.FullName -Raw -ErrorAction Stop
        
        # 检查常见问题
        $issues = @()
        
        # 检查无效字符
        if ($content -match '[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]') {
            $issues += "包含控制字符"
        }
        
        # 检查问号字符（通常是编码问题）
        if ($content -match '�') {
            $issues += "包含无效字符(�)"
        }
        
        # 检查错误处理
        if ($content -notmatch 'try\s*{' -and $content -notmatch 'catch\s*{') {
            $issues += "缺少错误处理"
        }
        
        # 检查等待时间
        if ($content -match 'Start-Sleep\s+-Seconds\s+[0-9]{3,}') {
            $issues += "等待时间过长"
        }
        
        # 显示问题
        if ($issues.Count -gt 0) {
            Write-Host "  发现的问题:" -ForegroundColor Red
            foreach ($issue in $issues) {
                Write-Host "    - $issue" -ForegroundColor Red
            }
        } else {
            Write-Host "  ✓ 脚本结构良好" -ForegroundColor Green
        }
        
        # 优化内容
        $optimizedContent = $content
        
        # 修复编码问题
        $optimizedContent = $optimizedContent -replace '�', ''
        $optimizedContent = $optimizedContent -replace '[\u0000-\u001F]', ''
        
        # 添加错误处理（如果缺少）
        if ($optimizedContent -notmatch 'try\s*{' -and $optimizedContent -match 'Write-Host') {
            # 在第一个Write-Host前添加try
            $lines = $optimizedContent -split "`n"
            $newLines = @()
            $tryAdded = $false
            
            foreach ($line in $lines) {
                if (-not $tryAdded -and $line -match 'Write-Host') {
                    $newLines += 'try {'
                    $newLines += '    $ErrorActionPreference = "Stop"'
                    $tryAdded = $true
                }
                $newLines += $line
            }
            
            if ($tryAdded) {
                $newLines += '}'
                $newLines += 'catch {'
                $newLines += '    Write-Host "错误: $($_.Exception.Message)" -ForegroundColor Red'
                $newLines += '    Write-Host "脚本: ' + $script.Name + '" -ForegroundColor Yellow'
                $newLines += '    Start-Sleep -Seconds 5'
                $newLines += '}'
                $optimizedContent = $newLines -join "`n"
            }
        }
        
        # 优化等待时间
        $optimizedContent = $optimizedContent -replace 'Start-Sleep\s+-Seconds\s+([0-9]{3,})', 'Start-Sleep -Seconds 30  # 优化: 原为$1秒'
        
        # 添加执行时间记录
        if ($optimizedContent -notmatch 'Measure-Command') {
            $optimizedContent = "# 脚本执行时间记录`n" + 
                               "`$scriptStartTime = Get-Date`n" + 
                               "`n" + $optimizedContent + 
                               "`n`n# 执行时间统计`n" +
                               "`$scriptEndTime = Get-Date`n" +
                               "`$executionTime = `$scriptEndTime - `$scriptStartTime`n" +
                               "Write-Host `"脚本执行完成，耗时: `$(`$executionTime.ToString('hh\:mm\:ss'))`" -ForegroundColor Green"
        }
        
        # 保存优化后的脚本
        $optimizedPath = $script.FullName -replace '\.ps1$', '_optimized.ps1'
        $optimizedContent | Out-File -FilePath $optimizedPath -Encoding UTF8 -Force
        
        # 比较文件大小
        $originalSize = (Get-Item $script.FullName).Length
        $optimizedSize = (Get-Item $optimizedPath).Length
        
        Write-Host "  ✓ 优化完成" -ForegroundColor Green
        Write-Host "    原始大小: $([math]::Round($originalSize/1024, 2)) KB" -ForegroundColor White
        Write-Host "    优化后大小: $([math]::Round($optimizedSize/1024, 2)) KB" -ForegroundColor White
        
        $optimizedCount++
        
    } catch {
        Write-Host "  ✗ 优化失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 3. 创建测试脚本
Write-Host "`n创建测试脚本..." -ForegroundColor Yellow
$testScript = @'
# 自动化脚本测试器
Write-Host "开始测试自动化脚本..." -ForegroundColor Cyan

# 测试环境检查
$tests = @(
    @{Name="PowerShell版本"; Test={ $PSVersionTable.PSVersion.Major -ge 5 }},
    @{Name="网络连接"; Test={ Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -InformationLevel Quiet }},
    @{Name="磁盘空间"; Test={ (Get-PSDrive C).Free -gt 1GB }},
    @{Name="内存可用"; Test={ (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory -gt 1GB }}
)

$passed = 0
$failed = 0

foreach ($test in $tests) {
    try {
        $result = & $test.Test
        if ($result) {
            Write-Host "  ✓ $($test.Name)" -ForegroundColor Green
            $passed++
        } else {
            Write-Host "  ✗ $($test.Name)" -ForegroundColor Red
            $failed++
        }
    } catch {
        Write-Host "  ✗ $($test.Name): $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    }
}

Write-Host "`n测试结果:" -ForegroundColor Cyan
Write-Host "  通过: $passed" -ForegroundColor Green
Write-Host "  失败: $failed" -ForegroundColor $(if ($failed -gt 0) { 'Red' } else { 'Green' })

if ($failed -eq 0) {
    Write-Host "`n✓ 环境测试通过，可以运行自动化脚本" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ 环境测试失败，请先解决问题" -ForegroundColor Red
}
'@

$testScriptPath = ".\automation_test.ps1"
$testScript | Out-File -FilePath $testScriptPath -Encoding UTF8
Write-Host "  ✓ 创建测试脚本: automation_test.ps1" -ForegroundColor Green

# 4. 总结
Write-Host "`n脚本优化完成！" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Cyan
Write-Host "优化了 $optimizedCount 个脚本文件" -ForegroundColor White
Write-Host "创建了测试脚本: automation_test.ps1" -ForegroundColor White
Write-Host "`n建议:" -ForegroundColor Cyan
Write-Host "  1. 先运行 automation_test.ps1 测试环境" -ForegroundColor White
Write-Host "  2. 使用 *_optimized.ps1 文件运行优化后的脚本" -ForegroundColor White
Write-Host "  3. 监控脚本执行日志，确保稳定运行" -ForegroundColor White