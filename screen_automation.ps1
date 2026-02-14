# 屏幕识别与鼠标自动化脚本
# 用于自动识别屏幕元素并执行鼠标操作

# 导入必要的模块
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 全局变量
$global:screenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
$global:screenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height
$global:mouseSpeed = 1  # 鼠标移动速度 (1-10)

# 函数：截取屏幕截图
function Capture-Screen {
    param(
        [string]$outputPath = "C:\Users\Administrator\.openclaw\workspace\screenshot.png"
    )
    
    try {
        # 创建位图对象
        $bitmap = New-Object System.Drawing.Bitmap $screenWidth, $screenHeight
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        
        # 截取屏幕
        $graphics.CopyFromScreen(0, 0, 0, 0, $bitmap.Size)
        
        # 保存截图
        $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        
        # 清理资源
        $graphics.Dispose()
        $bitmap.Dispose()
        
        Write-Host "屏幕截图已保存到: $outputPath" -ForegroundColor Green
        return $outputPath
    }
    catch {
        Write-Host "截取屏幕时出错: $_" -ForegroundColor Red
        return $null
    }
}

# 函数：移动鼠标到指定位置
function Move-MouseTo {
    param(
        [int]$x,
        [int]$y,
        [int]$duration = 100  # 移动持续时间(毫秒)
    )
    
    try {
        # 获取当前鼠标位置
        $currentPos = [System.Windows.Forms.Cursor]::Position
        
        # 计算移动步数
        $steps = [math]::Max(10, [math]::Ceiling($duration / 10))
        $stepX = ($x - $currentPos.X) / $steps
        $stepY = ($y - $currentPos.Y) / $steps
        
        # 平滑移动鼠标
        for ($i = 1; $i -le $steps; $i++) {
            $newX = [math]::Round($currentPos.X + ($stepX * $i))
            $newY = [math]::Round($currentPos.Y + ($stepY * $i))
            [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($newX, $newY)
            Start-Sleep -Milliseconds ($duration / $steps)
        }
        
        Write-Host "鼠标已移动到位置: ($x, $y)" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "移动鼠标时出错: $_" -ForegroundColor Red
        return $false
    }
}

# 函数：点击鼠标
function Click-Mouse {
    param(
        [string]$button = "left",  # left, right, middle
        [int]$x = -1,
        [int]$y = -1,
        [int]$clicks = 1
    )
    
    try {
        # 如果需要，先移动鼠标
        if ($x -ne -1 -and $y -ne -1) {
            Move-MouseTo -x $x -y $y
        }
        
        # 导入Windows API
        Add-Type @"
            using System;
            using System.Runtime.InteropServices;
            public class MouseClick {
                [DllImport("user32.dll", CharSet=CharSet.Auto, CallingConvention=CallingConvention.StdCall)]
                public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint cButtons, uint dwExtraInfo);
                
                private const uint MOUSEEVENTF_LEFTDOWN = 0x02;
                private const uint MOUSEEVENTF_LEFTUP = 0x04;
                private const uint MOUSEEVENTF_RIGHTDOWN = 0x08;
                private const uint MOUSEEVENTF_RIGHTUP = 0x10;
                private const uint MOUSEEVENTF_MIDDLEDOWN = 0x20;
                private const uint MOUSEEVENTF_MIDDLEUP = 0x40;
                
                public static void Click(string button, int clicks) {
                    uint downFlag = 0;
                    uint upFlag = 0;
                    
                    switch(button.ToLower()) {
                        case "left":
                            downFlag = MOUSEEVENTF_LEFTDOWN;
                            upFlag = MOUSEEVENTF_LEFTUP;
                            break;
                        case "right":
                            downFlag = MOUSEEVENTF_RIGHTDOWN;
                            upFlag = MOUSEEVENTF_RIGHTUP;
                            break;
                        case "middle":
                            downFlag = MOUSEEVENTF_MIDDLEDOWN;
                            upFlag = MOUSEEVENTF_MIDDLEUP;
                            break;
                    }
                    
                    for(int i = 0; i < clicks; i++) {
                        mouse_event(downFlag, 0, 0, 0, 0);
                        mouse_event(upFlag, 0, 0, 0, 0);
                        System.Threading.Thread.Sleep(50);
                    }
                }
            }
"@
        
        # 执行点击
        [MouseClick]::Click($button, $clicks)
        
        Write-Host "鼠标点击完成: $button 按钮, $clicks 次" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "点击鼠标时出错: $_" -ForegroundColor Red
        return $false
    }
}

# 函数：输入文本
function Type-Text {
    param(
        [string]$text,
        [int]$delay = 50  # 每个字符之间的延迟(毫秒)
    )
    
    try {
        Add-Type -AssemblyName System.Windows.Forms
        
        foreach ($char in $text.ToCharArray()) {
            [System.Windows.Forms.SendKeys]::SendWait($char)
            Start-Sleep -Milliseconds $delay
        }
        
        Write-Host "已输入文本: $text" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "输入文本时出错: $_" -ForegroundColor Red
        return $false
    }
}

# 函数：查找屏幕上的颜色
function Find-ColorOnScreen {
    param(
        [string]$colorHex,  # 格式: "#RRGGBB"
        [int]$tolerance = 10  # 颜色容差
    )
    
    try {
        # 截取屏幕
        $screenshotPath = Capture-Screen
        if (-not $screenshotPath) { return $null }
        
        # 加载图像
        $bitmap = [System.Drawing.Bitmap]::FromFile($screenshotPath)
        
        # 解析颜色
        $targetColor = [System.Drawing.ColorTranslator]::FromHtml($colorHex)
        
        # 搜索颜色
        $foundPoints = @()
        for ($x = 0; $x -lt $bitmap.Width; $x += 5) {  # 每5像素采样一次
            for ($y = 0; $y -lt $bitmap.Height; $y += 5) {
                $pixelColor = $bitmap.GetPixel($x, $y)
                
                # 计算颜色差异
                $diff = [math]::Abs($pixelColor.R - $targetColor.R) +
                        [math]::Abs($pixelColor.G - $targetColor.G) +
                        [math]::Abs($pixelColor.B - $targetColor.B)
                
                if ($diff -le $tolerance) {
                    $foundPoints += @{X = $x; Y = $y}
                }
            }
        }
        
        $bitmap.Dispose()
        
        if ($foundPoints.Count -gt 0) {
            Write-Host "找到颜色 $colorHex 的位置: $($foundPoints.Count) 个点" -ForegroundColor Green
            return $foundPoints
        }
        else {
            Write-Host "未找到颜色 $colorHex" -ForegroundColor Yellow
            return $null
        }
    }
    catch {
        Write-Host "查找颜色时出错: $_" -ForegroundColor Red
        return $null
    }
}

# 函数：自动登录GitHub示例
function Auto-LoginGitHub {
    Write-Host "开始自动登录GitHub..." -ForegroundColor Cyan
    
    # 1. 打开浏览器到GitHub登录页面
    Start-Process "https://github.com/login"
    Start-Sleep -Seconds 3
    
    # 2. 点击用户名输入框 (假设在屏幕中间偏上位置)
    $usernameX = [math]::Round($screenWidth * 0.5)
    $usernameY = [math]::Round($screenHeight * 0.4)
    Click-Mouse -x $usernameX -y $usernameY
    
    # 3. 输入用户名
    Type-Text -text "AHPNFT" -delay 100
    
    # 4. 按Tab键切换到密码框
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    Start-Sleep -Milliseconds 500
    
    # 5. 输入密码 (这里需要用户提供)
    # Type-Text -text "YOUR_PASSWORD" -delay 100
    
    # 6. 点击登录按钮 (假设在用户名框下方)
    $loginX = $usernameX
    $loginY = $usernameY + 80
    Click-Mouse -x $loginX -y $loginY
    
    Write-Host "GitHub登录流程完成" -ForegroundColor Green
}

# 函数：自动完成GitHub推送
function Auto-GitHubPush {
    Write-Host "开始自动完成GitHub推送..." -ForegroundColor Cyan
    
    # 1. 打开命令提示符或PowerShell
    [System.Windows.Forms.SendKeys]::SendWait("^{ESC}")  # Win键
    Start-Sleep -Milliseconds 500
    Type-Text -text "powershell" -delay 100
    Start-Sleep -Milliseconds 500
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Start-Sleep -Seconds 2
    
    # 2. 导航到工作目录
    Type-Text -text "cd 'C:\Users\Administrator\.openclaw\workspace'" -delay 50
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Start-Sleep -Milliseconds 500
    
    # 3. 执行Git推送命令
    Type-Text -text "git push -u origin main" -delay 50
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    
    Write-Host "GitHub推送命令已执行" -ForegroundColor Green
}

# 主菜单
function Show-Menu {
    Clear-Host
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "       屏幕识别与鼠标自动化工具" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. 截取屏幕截图" -ForegroundColor Yellow
    Write-Host "2. 移动鼠标到指定位置" -ForegroundColor Yellow
    Write-Host "3. 点击鼠标" -ForegroundColor Yellow
    Write-Host "4. 输入文本" -ForegroundColor Yellow
    Write-Host "5. 查找屏幕上的颜色" -ForegroundColor Yellow
    Write-Host "6. 自动登录GitHub (示例)" -ForegroundColor Yellow
    Write-Host "7. 自动完成GitHub推送" -ForegroundColor Yellow
    Write-Host "8. 测试所有功能" -ForegroundColor Green
    Write-Host "9. 退出" -ForegroundColor Red
    Write-Host ""
}

# 主程序
function Main {
    do {
        Show-Menu
        $choice = Read-Host "请选择操作 (1-9)"
        
        switch ($choice) {
            "1" {
                $path = Capture-Screen
                if ($path) {
                    Write-Host "截图已保存: $path" -ForegroundColor Green
                }
                Pause
            }
            "2" {
                $x = Read-Host "输入X坐标"
                $y = Read-Host "输入Y坐标"
                Move-MouseTo -x $x -y $y
                Pause
            }
            "3" {
                $x = Read-Host "输入X坐标 (或按Enter使用当前位置)"
                $y = Read-Host "输入Y坐标 (或按Enter使用当前位置)"
                $button = Read-Host "选择按钮 (left/right/middle) [默认: left]"
                if (-not $button) { $button = "left" }
                
                if ($x -and $y) {
                    Click-Mouse -x $x -y $y -button $button
                }
                else {
                    Click-Mouse -button $button
                }
                Pause
            }
            "4" {
                $text = Read-Host "输入要输入的文本"
                Type-Text -text $text
                Pause
            }
            "5" {
                $color = Read-Host "输入颜色代码 (格式: #RRGGBB)"
                $points = Find-ColorOnScreen -colorHex $color
                if ($points) {
                    Write-Host "找到的第一个点位置: X=$($points[0].X), Y=$($points[0].Y)" -ForegroundColor Green
                }
                Pause
            }
            "6" {
                Auto-LoginGitHub
                Pause
            }
            "7" {
                Auto-GitHubPush
                Pause
            }
            "8" {
                Write-Host "开始测试所有功能..." -ForegroundColor Cyan
                
                # 测试截图
                Write-Host "1. 测试截图..." -ForegroundColor Yellow
                $screenshot = Capture-Screen
                
                # 测试鼠标移动
                Write-Host "2. 测试鼠标移动..." -ForegroundColor Yellow
                Move-MouseTo -x 100 -y 100
                Start-Sleep -Milliseconds 500
                Move-MouseTo -x 200 -y 200
                
                # 测试鼠标点击
                Write-Host "3. 测试鼠标点击..." -ForegroundColor Yellow
                Click-Mouse -x 300 -y 300
                
                # 测试文本输入
                Write-Host "4. 测试文本输入..." -ForegroundColor Yellow
                Type-Text -text "Hello, World!" -delay 30
                
                Write-Host "所有测试完成!" -ForegroundColor Green
                Pause
            }
            "9" {
                Write-Host "退出程序..." -ForegroundColor Cyan
                return
            }
            default {
                Write-Host "无效的选择，请重试。" -ForegroundColor Red
                Pause
            }
        }
    } while ($true)
}

# 运行主程序
if ($MyInvocation.InvocationName -ne '.') {
    Main
}