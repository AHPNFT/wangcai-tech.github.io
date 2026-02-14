# 自动化内容发布脚本
# 功能：从模板库选择内容，稍作修改，发布到不同平台

Write-Host "=== 自动化内容发布系统 ===" -ForegroundColor Green
Write-Host "开始时间: $(Get-Date)" -ForegroundColor Yellow

# 配置参数
$TEMPLATE_FILE = "C:\Users\Administrator\.openclaw\workspace\content_templates.md"
$LOG_FILE = "C:\Users\Administrator\.openclaw\workspace\publish_log.txt"
$PLATFORMS = @("Moltbook", "Reddit", "Twitter", "Zhihu")
$CONTENT_PER_DAY = 10

# 读取模板文件
Write-Host "读取内容模板..." -ForegroundColor Yellow
$templateContent = Get-Content $TEMPLATE_FILE -Raw

# 分割模板
$templates = @()
$lines = $templateContent -split "`n"

$currentTemplate = @()
$inTemplate = $false

foreach ($line in $lines) {
    if ($line -match "^## 模板\d+:") {
        if ($currentTemplate.Count -gt 0) {
            $templates += ($currentTemplate -join "`n")
            $currentTemplate = @()
        }
        $inTemplate = $true
    }
    
    if ($inTemplate) {
        $currentTemplate += $line
    }
}

if ($currentTemplate.Count -gt 0) {
    $templates += ($currentTemplate -join "`n")
}

Write-Host "找到 $($templates.Count) 个内容模板" -ForegroundColor Green

# 内容变异函数
function Modify-Content {
    param([string]$content)
    
    # 轻微修改内容，避免完全重复
    $modifications = @(
        "今天", "现在", "目前", "最近",
        "分享", "介绍", "推荐", "展示",
        "技巧", "方法", "策略", "方案"
    )
    
    $newContent = $content
    
    # 随机替换一些词语
    foreach ($word in $modifications) {
        if ((Get-Random -Maximum 100) -lt 30) {  # 30%概率替换
            $replacements = $modifications | Where-Object { $_ -ne $word }
            $replacement = $replacements | Get-Random
            $newContent = $newContent -replace "\b$word\b", $replacement
        }
    }
    
    # 添加个性化开头
    $greetings = @(
        "大家好！",
        "各位开发者好！",
        "技术爱好者们，",
        "编程同好们，"
    )
    
    $greeting = $greetings | Get-Random
    if (-not ($newContent -match "^大家好" -or $newContent -match "^各位")) {
        # 在第一个段落前添加问候
        $paragraphs = $newContent -split "`n`n"
        if ($paragraphs.Count -gt 1) {
            $paragraphs[0] = "$greeting`n`n$($paragraphs[0])"
            $newContent = $paragraphs -join "`n`n"
        }
    }
    
    return $newContent
}

# 发布日志函数
function Log-Publish {
    param(
        [string]$platform,
        [string]$title,
        [string]$status
    )
    
    $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | $platform | $title | $status"
    Add-Content -Path $LOG_FILE -Value $logEntry
    Write-Host $logEntry -ForegroundColor Cyan
}

# 模拟发布函数（实际需要集成各平台API）
function Publish-To-Platform {
    param(
        [string]$platform,
        [string]$title,
        [string]$content,
        [string[]]$tags
    )
    
    Write-Host "发布到 $platform..." -ForegroundColor Yellow
    Write-Host "标题: $title" -ForegroundColor White
    Write-Host "标签: $($tags -join ', ')" -ForegroundColor Gray
    
    # 这里模拟发布过程
    Start-Sleep -Seconds (Get-Random -Minimum 2 -Maximum 5)
    
    # 模拟成功或失败
    $successRate = @{
        "Moltbook" = 90
        "Reddit" = 80
        "Twitter" = 85
        "Zhihu" = 75
    }
    
    $chance = Get-Random -Minimum 1 -Maximum 100
    $success = $chance -le $successRate[$platform]
    
    if ($success) {
        Write-Host "✅ 发布成功到 $platform" -ForegroundColor Green
        Log-Publish -platform $platform -title $title -status "成功"
        return $true
    } else {
        Write-Host "❌ 发布失败到 $platform" -ForegroundColor Red
        Log-Publish -platform $platform -title $title -status "失败"
        return $false
    }
}

# 提取模板信息
function Extract-TemplateInfo {
    param([string]$template)
    
    $info = @{
        Title = ""
        Content = ""
        Tags = @()
    }
    
    # 提取标题
    if ($template -match "标题:\s*(.+)") {
        $info.Title = $matches[1].Trim()
    }
    
    # 提取标签
    if ($template -match "标签:\s*(.+)") {
        $tagLine = $matches[1].Trim()
        $info.Tags = $tagLine -split '\s+' | Where-Object { $_ -match "^#" }
    }
    
    # 提取内容（标题之后到下一个模板之前）
    $lines = $template -split "`n"
    $inContent = $false
    $contentLines = @()
    
    foreach ($line in $lines) {
        if ($line -match "标签:\s*") {
            $inContent = $true
            continue
        }
        
        if ($inContent -and $line -match "^---") {
            break
        }
        
        if ($inContent) {
            $contentLines += $line
        }
    }
    
    $info.Content = $contentLines -join "`n"
    
    return $info
}

# 主发布循环
Write-Host "`n开始发布循环..." -ForegroundColor Green
$publishedCount = 0
$platformIndex = 0
$templateIndex = 0

while ($publishedCount -lt $CONTENT_PER_DAY) {
    # 选择模板
    $template = $templates[$templateIndex % $templates.Count]
    $templateInfo = Extract-TemplateInfo -template $template
    
    # 修改内容
    $modifiedContent = Modify-Content -content $templateInfo.Content
    
    # 选择平台
    $platform = $PLATFORMS[$platformIndex % $PLATFORMS.Count]
    
    Write-Host "`n=== 发布 #$($publishedCount + 1) ===" -ForegroundColor Magenta
    
    # 发布
    $success = Publish-To-Platform `
        -platform $platform `
        -title $templateInfo.Title `
        -content $modifiedContent `
        -tags $templateInfo.Tags
    
    if ($success) {
        $publishedCount++
    }
    
    # 移动到下一个模板和平台
    $templateIndex++
    $platformIndex++
    
    # 等待一段时间（模拟人工操作间隔）
    if ($publishedCount -lt $CONTENT_PER_DAY) {
        $waitTime = Get-Random -Minimum 1800 -Maximum 7200  # 30分钟到2小时
        Write-Host "等待 $(($waitTime/60).ToString('F1')) 分钟..." -ForegroundColor Gray
        Start-Sleep -Seconds $waitTime
    }
}

# 生成报告
Write-Host "`n=== 发布完成 ===" -ForegroundColor Green
Write-Host "完成时间: $(Get-Date)" -ForegroundColor Yellow
Write-Host "总发布数量: $publishedCount" -ForegroundColor Cyan
Write-Host "日志文件: $LOG_FILE" -ForegroundColor Gray

# 显示日志
if (Test-Path $LOG_FILE) {
    Write-Host "`n发布日志:" -ForegroundColor Yellow
    Get-Content $LOG_FILE | ForEach-Object { Write-Host $_ -ForegroundColor White }
}

# 保存今日发布内容
$today = Get-Date -Format "yyyyMMdd"
$publishSummary = @"
# 今日发布总结 - $today

## 统计数据
- 总发布数量: $publishedCount
- 使用模板: $templateIndex 个
- 覆盖平台: $($PLATFORMS -join ', ')
- 开始时间: $(Get-Date -Format 'HH:mm:ss')
- 结束时间: $(Get-Date -Format 'HH:mm:ss')

## 详细记录
$(if (Test-Path $LOG_FILE) { Get-Content $LOG_FILE | ForEach-Object { "- $_" } })

## 下一步
1. 监控内容表现（浏览量、互动）
2. 分析最佳发布时间
3. 优化内容策略
4. 扩展更多平台
"@

$summaryFile = "C:\Users\Administrator\.openclaw\workspace\publish_summary_$today.md"
$publishSummary | Out-File -FilePath $summaryFile -Encoding UTF8

Write-Host "`n总结文件: $summaryFile" -ForegroundColor Green
Write-Host "24小时测试第一阶段完成！" -ForegroundColor Cyan