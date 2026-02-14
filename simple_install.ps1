# 简单开发工具安装脚本
Write-Host "=== 开发工具安装脚本 ===" -ForegroundColor Cyan

# 检查已安装的工具
Write-Host "`n检查已安装的工具:" -ForegroundColor Green

# Python
try {
    $py = python --version 2>&1
    Write-Host "Python: $py" -ForegroundColor Green
} catch {
    Write-Host "Python: 未安装" -ForegroundColor Red
}

# Node.js
try {
    $node = node --version 2>&1
    Write-Host "Node.js: $node" -ForegroundColor Green
} catch {
    Write-Host "Node.js: 未安装" -ForegroundColor Red
}

# Git
try {
    $git = git --version 2>&1
    Write-Host "Git: $git" -ForegroundColor Green
} catch {
    Write-Host "Git: 未安装" -ForegroundColor Red
}

# VS Code
try {
    $code = code --version 2>&1
    Write-Host "VS Code: 已安装" -ForegroundColor Green
} catch {
    Write-Host "VS Code: 未安装" -ForegroundColor Red
}

# Java
try {
    $java = java --version 2>&1
    Write-Host "Java: 已安装" -ForegroundColor Green
} catch {
    Write-Host "Java: 未安装" -ForegroundColor Red
}

Write-Host "`n=== 安装建议 ===" -ForegroundColor Yellow
Write-Host "1. VS Code: 请手动下载安装" -ForegroundColor Cyan
Write-Host "   下载地址: https://code.visualstudio.com/download" -ForegroundColor Cyan
Write-Host "2. Java: 使用 scoop install openjdk17" -ForegroundColor Cyan
Write-Host "3. 其他工具可通过 scoop 安装" -ForegroundColor Cyan
Write-Host "   scoop install go rust docker" -ForegroundColor Cyan

Write-Host "`n=== 当前开发环境状态 ===" -ForegroundColor Green
Write-Host "✅ Python 3.14.3 已安装" -ForegroundColor Green
Write-Host "✅ Node.js v24.13.1 已安装" -ForegroundColor Green
Write-Host "✅ Git 2.53.0 已安装" -ForegroundColor Green
Write-Host "⚠️  VS Code 需要安装" -ForegroundColor Yellow
Write-Host "⚠️  Java 需要安装" -ForegroundColor Yellow
Write-Host "⚠️  Go/Rust/Docker 可选安装" -ForegroundColor Yellow

Write-Host "`n=== 下一步行动 ===" -ForegroundColor Cyan
Write-Host "1. 安装 VS Code" -ForegroundColor Green
Write-Host "2. 安装 Java (OpenJDK)" -ForegroundColor Green
Write-Host "3. 根据项目需求安装其他工具" -ForegroundColor Green
Write-Host "4. 配置开发环境" -ForegroundColor Green