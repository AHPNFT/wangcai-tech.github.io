# 开发工具安装脚本
Write-Host "=== 开发工具安装脚本 ===" -ForegroundColor Cyan
Write-Host "开始时间: $(Get-Date)" -ForegroundColor Yellow

# 检查已安装的工具
Write-Host "`n=== 检查已安装的工具 ===" -ForegroundColor Green

$tools = @{
    "Python" = { python --version 2>&1 }
    "Node.js" = { node --version 2>&1 }
    "Git" = { git --version 2>&1 }
    "VS Code" = { code --version 2>&1 }
    "Java" = { java --version 2>&1 }
    "Go" = { go version 2>&1 }
    "Rust" = { rustc --version 2>&1 }
    "Docker" = { docker --version 2>&1 }
}

foreach ($tool in $tools.Keys) {
    try {
        $result = Invoke-Command -ScriptBlock $tools[$tool] -ErrorAction SilentlyContinue
        if ($LASTEXITCODE -eq 0 -or $result -match "version") {
            Write-Host "OK $tool 已安装: $($result | Select-Object -First 1)" -ForegroundColor Green
        } else {
            Write-Host "NO $tool 未安装" -ForegroundColor Red
        }
    } catch {
        Write-Host "NO $tool 未安装" -ForegroundColor Red
    }
}

# 安装缺失的工具
Write-Host "`n=== 安装缺失的工具 ===" -ForegroundColor Green

# 1. 安装VS Code
if (!(Get-Command code -ErrorAction SilentlyContinue)) {
    Write-Host "正在安装 VS Code..." -ForegroundColor Yellow
    # 下载VS Code安装程序
    $vscodeUrl = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"
    $installerPath = "$env:TEMP\VSCodeSetup-x64.exe"
    
    try {
        Invoke-WebRequest -Uri $vscodeUrl -OutFile $installerPath
        Start-Process -FilePath $installerPath -ArgumentList "/verysilent /mergetasks=!runcode" -Wait
        Write-Host "OK VS Code 安装完成" -ForegroundColor Green
    } catch {
        Write-Host "NO VS Code 安装失败: $_" -ForegroundColor Red
    }
}

# 2. 安装Java (OpenJDK)
if (!(Get-Command java -ErrorAction SilentlyContinue)) {
    Write-Host "正在安装 Java (OpenJDK 17)..." -ForegroundColor Yellow
    try {
        scoop install openjdk17
        Write-Host "✅ Java 安装完成" -ForegroundColor Green
    } catch {
        Write-Host "❌ Java 安装失败，尝试备用方法..." -ForegroundColor Yellow
        # 备用方法：直接下载Zulu JDK
        $jdkUrl = "https://cdn.azul.com/zulu/bin/zulu17.52.17-ca-jdk17.0.14-win_x64.zip"
        $jdkZip = "$env:TEMP\zulu-jdk.zip"
        $jdkPath = "C:\Program Files\Java\zulu17"
        
        try {
            Invoke-WebRequest -Uri $jdkUrl -OutFile $jdkZip
            Expand-Archive -Path $jdkZip -DestinationPath $jdkPath -Force
            # 添加Java到PATH
            $env:Path += ";$jdkPath\bin"
            [Environment]::SetEnvironmentVariable("Path", $env:Path, [EnvironmentVariableTarget]::Machine)
            Write-Host "✅ Java (Zulu JDK) 安装完成" -ForegroundColor Green
        } catch {
            Write-Host "❌ Java 安装完全失败" -ForegroundColor Red
        }
    }
}

# 3. 安装Go
if (!(Get-Command go -ErrorAction SilentlyContinue)) {
    Write-Host "正在安装 Go..." -ForegroundColor Yellow
    try {
        scoop install go
        Write-Host "✅ Go 安装完成" -ForegroundColor Green
    } catch {
        Write-Host "❌ Go 安装失败" -ForegroundColor Red
    }
}

# 4. 安装Rust
if (!(Get-Command rustc -ErrorAction SilentlyContinue)) {
    Write-Host "正在安装 Rust..." -ForegroundColor Yellow
    try {
        # 使用rustup安装
        Invoke-WebRequest -Uri "https://win.rustup.rs/x86_64" -OutFile "$env:TEMP\rustup-init.exe"
        Start-Process -FilePath "$env:TEMP\rustup-init.exe" -ArgumentList "-y" -Wait
        Write-Host "✅ Rust 安装完成" -ForegroundColor Green
    } catch {
        Write-Host "❌ Rust 安装失败" -ForegroundColor Red
    }
}

# 5. 安装Docker Desktop
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "正在安装 Docker Desktop..." -ForegroundColor Yellow
    Write-Host "注意: Docker Desktop需要手动安装，请访问:" -ForegroundColor Cyan
    Write-Host "https://www.docker.com/products/docker-desktop/" -ForegroundColor Cyan
    Write-Host "下载后运行安装程序" -ForegroundColor Cyan
}

# 6. 安装其他有用的工具
Write-Host "`n=== 安装其他开发工具 ===" -ForegroundColor Green

$otherTools = @(
    "7zip",
    "curl",
    "wget",
    "make",
    "cmake",
    "ninja",
    "postman",
    "dbeaver",
    "everything",
    "notepadplusplus"
)

foreach ($tool in $otherTools) {
    Write-Host "检查 $tool..." -ForegroundColor Gray
    try {
        scoop install $tool
        Write-Host "✅ $tool 安装完成" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  $tool 安装跳过" -ForegroundColor Yellow
    }
}

# 安装Python包
Write-Host "`n=== 安装Python开发包 ===" -ForegroundColor Green
$pythonPackages = @(
    "pip",
    "virtualenv",
    "jupyter",
    "numpy",
    "pandas",
    "matplotlib",
    "requests",
    "flask",
    "django",
    "pytest",
    "black",
    "flake8",
    "mypy"
)

foreach ($pkg in $pythonPackages) {
    Write-Host "安装 $pkg..." -ForegroundColor Gray
    try {
        pip install $pkg --quiet
        Write-Host "✅ $pkg 安装完成" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  $pkg 安装失败" -ForegroundColor Yellow
    }
}

# 安装Node.js包
Write-Host "`n=== 安装Node.js开发包 ===" -ForegroundColor Green
$nodePackages = @(
    "npm",
    "yarn",
    "typescript",
    "ts-node",
    "nodemon",
    "express",
    "react",
    "vue",
    "angular",
    "jest",
    "eslint",
    "prettier",
    "webpack"
)

foreach ($pkg in $nodePackages) {
    Write-Host "安装 $pkg..." -ForegroundColor Gray
    try {
        npm install -g $pkg --silent
        Write-Host "✅ $pkg 安装完成" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  $pkg 安装失败" -ForegroundColor Yellow
    }
}

# 最终验证
Write-Host "`n=== 最终验证 ===" -ForegroundColor Cyan
Write-Host "结束时间: $(Get-Date)" -ForegroundColor Yellow

foreach ($tool in $tools.Keys) {
    try {
        $result = Invoke-Command -ScriptBlock $tools[$tool] -ErrorAction SilentlyContinue
        if ($LASTEXITCODE -eq 0 -or $result -match "version") {
            Write-Host "✅ $tool: $($result | Select-Object -First 1)" -ForegroundColor Green
        } else {
            Write-Host "❌ $tool: 未安装" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ $tool: 未安装" -ForegroundColor Red
    }
}

Write-Host "`n=== 安装完成 ===" -ForegroundColor Cyan
Write-Host "建议重启终端以使所有更改生效" -ForegroundColor Yellow
Write-Host "下一步: 配置VS Code扩展和开发环境" -ForegroundColor Green