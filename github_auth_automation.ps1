# GitHub认证自动化脚本
# 使用屏幕识别自动完成GitHub认证流程

# 导入屏幕自动化模块
. "C:\Users\Administrator\.openclaw\workspace\screen_automation.ps1"

# 配置参数
$config = @{
    # GitHub相关
    GitHubUsername = "AHPNFT"
    GitHubRepo = "wangcai-tech.github.io"
    
    # 屏幕坐标 (可能需要根据实际屏幕调整)
    ScreenPositions = @{
        # Chrome浏览器位置
        ChromeIcon = @{X = 100; Y = 100}  # 任务栏Chrome图标位置
        
        # GitHub页面元素 (相对位置，需要根据实际页面调整)
        GitHubLoginButton = @{X = 1200; Y = 400}  # 登录按钮
        UsernameField = @{X = 1200; Y = 450}      # 用户名输入框
        PasswordField = @{X = 1200; Y = 500}      # 密码输入框
        SignInButton = @{X = 1200; Y = 550}       # 登录按钮
        
        # GitHub令牌页面
        SettingsMenu = @{X = 1300; Y = 100}       # 设置菜单
        DeveloperSettings = @{X = 1200; Y = 200}  # 开发者设置
        PersonalAccessTokens = @{X = 1200; Y = 300} # 个人访问令牌
        GenerateNewToken = @{X = 1200; Y = 400}   # 生成新令牌按钮
        
        # 令牌配置
        TokenNote = @{X = 1200; Y = 450}          # 令牌备注输入框
        Expiration = @{X = 1200; Y = 500}         # 过期时间下拉框
        RepoScope = @{X = 1200; Y = 550}          # repo权限复选框
        GenerateTokenButton = @{X = 1200; Y = 600} # 生成令牌按钮
        
        # 命令提示符位置
        CMDIcon = @{X = 100; Y = 150}             # 任务栏CMD图标
        PowerShellIcon = @{X = 100; Y = 200}      # 任务栏PowerShell图标
    }
    
    # 颜色识别配置 (用于验证页面加载)
    Colors = @{
        GitHubHeader = "#24292f"      # GitHub头部颜色
        LoginButton = "#2da44e"       # 登录按钮绿色
        WhiteBackground = "#ffffff"   # 白色背景
    }
    
    # 延迟配置 (毫秒)
    Delays = @{
        PageLoad = 3000               # 页面加载等待
        ElementLoad = 1000            # 元素加载等待
        Typing = 50                   # 打字延迟
        Navigation = 500              # 导航延迟
    }
}

# 函数：等待页面加载
function Wait-ForPageLoad {
    param(
        [string]$colorToFind = "#ffffff",
        [int]$timeout = 10000
    )
    
    Write-Host "等待页面加载..." -ForegroundColor Yellow
    $startTime = Get-Date
    $found = $false
    
    while (((Get-Date) - $startTime).TotalMilliseconds -lt $timeout) {
        $points = Find-ColorOnScreen -colorHex $colorToFind -tolerance 20
        if ($points -and $points.Count -gt 100) {
            $found = $true
            break
        }
        Start-Sleep -Milliseconds 500
    }
    
    if ($found) {
        Write-Host "页面加载完成" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "页面加载超时" -ForegroundColor Red
        return $false
    }
}

# 函数：打开Chrome浏览器
function Open-ChromeBrowser {
    Write-Host "打开Chrome浏览器..." -ForegroundColor Cyan
    
    # 点击任务栏Chrome图标
    Click-Mouse -x $config.ScreenPositions.ChromeIcon.X -y $config.ScreenPositions.ChromeIcon.Y
    Start-Sleep -Milliseconds $config.Delays.Navigation
    
    # 等待浏览器打开
    Start-Sleep -Seconds 2
    
    return $true
}

# 函数：导航到GitHub
function Navigate-ToGitHub {
    param(
        [string]$url = "https://github.com"
    )
    
    Write-Host "导航到GitHub: $url" -ForegroundColor Cyan
    
    # 按Ctrl+L聚焦地址栏
    [System.Windows.Forms.SendKeys]::SendWait("^l")
    Start-Sleep -Milliseconds 500
    
    # 输入GitHub地址
    Type-Text -text $url -delay $config.Delays.Typing
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    
    # 等待页面加载
    Start-Sleep -Milliseconds $config.Delays.PageLoad
    Wait-ForPageLoad -colorToFind $config.Colors.GitHubHeader
    
    return $true
}

# 函数：自动登录GitHub
function Auto-LoginToGitHub {
    param(
        [string]$username,
        [string]$password
    )
    
    Write-Host "开始自动登录GitHub..." -ForegroundColor Cyan
    
    # 导航到登录页面
    Navigate-ToGitHub -url "https://github.com/login"
    
    # 点击用户名输入框
    Click-Mouse -x $config.ScreenPositions.UsernameField.X -y $config.ScreenPositions.UsernameField.Y
    Start-Sleep -Milliseconds $config.Delays.ElementLoad
    
    # 输入用户名
    Type-Text -text $username -delay $config.Delays.Typing
    
    # 按Tab切换到密码框
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    Start-Sleep -Milliseconds $config.Delays.ElementLoad
    
    # 输入密码
    Type-Text -text $password -delay $config.Delays.Typing
    
    # 点击登录按钮
    Click-Mouse -x $config.ScreenPositions.SignInButton.X -y $config.ScreenPositions.SignInButton.Y
    
    # 等待登录完成
    Start-Sleep -Milliseconds $config.Delays.PageLoad
    
    Write-Host "GitHub登录完成" -ForegroundColor Green
    return $true
}

# 函数：生成GitHub个人访问令牌
function Generate-GitHubToken {
    param(
        [string]$tokenName = "OpenClaw-Auto-Push",
        [string]$expiration = "90"  # 90天
    )
    
    Write-Host "开始生成GitHub个人访问令牌..." -ForegroundColor Cyan
    
    # 导航到令牌设置页面
    Navigate-ToGitHub -url "https://github.com/settings/tokens"
    
    # 点击"Generate new token"按钮
    Click-Mouse -x $config.ScreenPositions.GenerateNewToken.X -y $config.ScreenPositions.GenerateNewToken.Y
    Start-Sleep -Milliseconds $config.Delays.PageLoad
    
    # 输入令牌备注
    Click-Mouse -x $config.ScreenPositions.TokenNote.X -y $config.ScreenPositions.TokenNote.Y
    Start-Sleep -Milliseconds $config.Delays.ElementLoad
    Type-Text -text $tokenName -delay $config.Delays.Typing
    
    # 选择过期时间 (按Tab多次到达过期时间选择)
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    Start-Sleep -Milliseconds 500
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    Start-Sleep -Milliseconds 500
    
    # 选择90天 (按下箭头2次选择90 days)
    [System.Windows.Forms.SendKeys]::SendWait("{DOWN}")
    Start-Sleep -Milliseconds 500
    [System.Windows.Forms.SendKeys]::SendWait("{DOWN}")
    Start-Sleep -Milliseconds 500
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    
    # 选择repo权限 (按Tab多次到达权限选择)
    for ($i = 0; $i -lt 5; $i++) {
        [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
        Start-Sleep -Milliseconds 300
    }
    
    # 选择repo权限 (按空格选中)
    [System.Windows.Forms.SendKeys]::SendWait(" ")
    Start-Sleep -Milliseconds 500
    
    # 滚动到生成按钮 (按Tab多次)
    for ($i = 0; $i -lt 10; $i++) {
        [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
        Start-Sleep -Milliseconds 300
    }
    
    # 点击生成令牌按钮
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    
    # 等待令牌生成
    Start-Sleep -Seconds 5
    
    Write-Host "GitHub令牌生成完成 (需要用户手动复制令牌)" -ForegroundColor Green
    Write-Host "请复制生成的令牌并告诉我" -ForegroundColor Yellow
    
    return $true
}

# 函数：配置Git使用令牌
function Configure-GitWithToken {
    param(
        [string]$token,
        [string]$username = "AHPNFT"
    )
    
    Write-Host "配置Git使用令牌..." -ForegroundColor Cyan
    
    # 打开PowerShell
    Click-Mouse -x $config.ScreenPositions.PowerShellIcon.X -y $config.ScreenPositions.PowerShellIcon.Y
    Start-Sleep -Seconds 2
    
    # 导航到工作目录
    Type-Text -text "cd 'C:\Users\Administrator\.openclaw\workspace'" -delay $config.Delays.Typing
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Start-Sleep -Milliseconds 500
    
    # 配置Git远程URL使用令牌
    $remoteUrl = "https://$username:$token@github.com/$username/$($config.GitHubRepo).git"
    Type-Text -text "git remote set-url origin '$remoteUrl'" -delay $config.Delays.Typing
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Start-Sleep -Milliseconds 500
    
    # 验证远程配置
    Type-Text -text "git remote -v" -delay $config.Delays.Typing
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Start-Sleep -Milliseconds 500
    
    # 执行Git推送
    Type-Text -text "git push -u origin main" -delay $config.Delays.Typing
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    
    Write-Host "Git配置完成，推送已执行" -ForegroundColor Green
    return $true
}

# 函数：完整的GitHub认证和推送流程
function Complete-GitHubAuthAndPush {
    Write-Host "开始完整的GitHub认证和推送流程..." -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    
    # 步骤1: 打开浏览器
    Write-Host "[1/5] 打开Chrome浏览器..." -ForegroundColor Yellow
    Open-ChromeBrowser
    
    # 步骤2: 登录GitHub (需要用户提供密码)
    Write-Host "[2/5] 准备登录GitHub..." -ForegroundColor Yellow
    Write-Host "需要您的GitHub密码来完成登录" -ForegroundColor Yellow
    $password = Read-Host "请输入GitHub密码" -AsSecureString
    $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
    )
    
    Auto-LoginToGitHub -username $config.GitHubUsername -password $plainPassword
    
    # 清除密码变量
    $plainPassword = $null
    [GC]::Collect()
    
    # 步骤3: 生成访问令牌
    Write-Host "[3/5] 生成GitHub访问令牌..." -ForegroundColor Yellow
    Generate-GitHubToken
    
    # 步骤4: 等待用户复制令牌
    Write-Host "[4/5] 等待用户提供生成的令牌..." -ForegroundColor Yellow
    $token = Read-Host "请粘贴生成的GitHub令牌"
    
    # 步骤5: 配置Git并推送
    Write-Host "[5/5] 配置Git并推送代码..." -ForegroundColor Yellow
    Configure-GitWithToken -token $token
    
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "GitHub认证和推送流程完成!" -ForegroundColor Green
    Write-Host "网站将在2-5分钟内自动部署" -ForegroundColor Green
    
    return $true
}

# 函数：简化流程 (仅推送，假设已登录)
function Quick-GitHubPush {
    Write-Host "开始快速GitHub推送..." -ForegroundColor Cyan
    
    # 打开PowerShell
    Click-Mouse -x $config.ScreenPositions.PowerShellIcon.X -y $config.ScreenPositions.PowerShellIcon.Y
    Start-Sleep -Seconds 2
    
    # 导航到工作目录
    Type-Text -text "cd 'C:\Users\Administrator\.openclaw\workspace'" -delay 50
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Start-Sleep -Milliseconds 500
    
    # 执行Git推送
    Type-Text -text "git push -u origin main" -delay 50
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    
    Write-Host "Git推送命令已执行" -ForegroundColor Green
    Write-Host "等待认证提示..." -ForegroundColor Yellow
    
    return $true
}

# 主菜单
function Show-GitHubMenu {
    Clear-Host
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "       GitHub认证自动化工具" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. 完整流程: GitHub认证 + 生成令牌 + 推送" -ForegroundColor Green
    Write-Host "2. 仅执行Git推送 (假设已登录)" -ForegroundColor Yellow
    Write-Host "3. 生成GitHub访问令牌" -ForegroundColor Yellow
    Write-Host "4. 测试屏幕坐标" -ForegroundColor Yellow
    Write-Host "5. 退出" -ForegroundColor Red
    Write-Host ""
    Write-Host "注意: 首次使用前可能需要调整屏幕坐标" -ForegroundColor Magenta
    Write-Host ""
}

# 函数：测试屏幕坐标
function Test-ScreenCoordinates {
    Write-Host "测试屏幕坐标..." -ForegroundColor Cyan
    Write-Host "屏幕分辨率: $screenWidth x $screenHeight" -ForegroundColor Yellow
    
    Write-Host "将依次测试5个位置，请观察鼠标移动..." -ForegroundColor Yellow
    
    $testPoints = @(
        @{Name = "左上角"; X = 100; Y = 100},
        @{Name = "右上角"; X = $screenWidth - 100; Y = 100},
        @{Name = "中心"; X = [math]::Round($screenWidth / 2); Y = [math]::Round($screenHeight / 2)},
        @{Name = "左下角"; X = 100; Y = $screenHeight - 100},
        @{Name = "右下角"; X = $screenWidth - 100; Y = $screenHeight - 100}
    )
    
    foreach ($point in $testPoints) {
        Write-Host "移动到: $($point.Name) ($($point.X), $($point.Y))" -ForegroundColor Yellow
        Move-MouseTo -x $point.X -y $point.Y -duration 500
        Start-Sleep -Seconds 1
    }
    
    Write-Host "屏幕坐标测试完成" -ForegroundColor Green
}

# 主程序
function GitHubMain {
    do {
        Show-GitHubMenu
        $choice = Read-Host "请选择操作 (1-5)"
        
        switch ($choice) {
            "1" {
                Write-Host "选择: 完整GitHub认证流程" -ForegroundColor Cyan
                Complete-GitHubAuthAndPush
                Pause
            }
            "2" {
                Write-Host "选择: 仅执行Git推送" -ForegroundColor Cyan
                Quick-GitHubPush
                Pause
            }
            "3" {
                Write-Host "选择: 生成GitHub访问令牌" -ForegroundColor Cyan
                Generate-GitHubToken
                Pause
            }
            "4" {
                Write-Host "选择: 测试屏幕坐标" -ForegroundColor Cyan
                Test-ScreenCoordinates
                Pause
            }
            "5" {
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
    GitHubMain
}