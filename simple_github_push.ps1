# Simple GitHub Push Automation
# Uses screen recognition to automate GitHub authentication

Write-Host "GitHub Push Automation Started" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Step 1: Check if we're in the right directory
$workspacePath = "C:\Users\Administrator\.openclaw\workspace"
if ((Get-Location).Path -ne $workspacePath) {
    Write-Host "Changing to workspace directory..." -ForegroundColor Yellow
    Set-Location $workspacePath
}

# Step 2: Check Git status
Write-Host "Checking Git status..." -ForegroundColor Yellow
git status

# Step 3: Try to push (this will trigger authentication if needed)
Write-Host "Attempting Git push..." -ForegroundColor Yellow
Write-Host "This may open a browser window for authentication" -ForegroundColor Yellow
Write-Host ""

# Execute git push
$pushResult = git push -u origin main 2>&1

# Check the result
if ($LASTEXITCODE -eq 0) {
    Write-Host "Git push successful!" -ForegroundColor Green
    Write-Host "Website will be deployed in 2-5 minutes" -ForegroundColor Green
} else {
    Write-Host "Git push failed or requires authentication" -ForegroundColor Red
    Write-Host "Error output:" -ForegroundColor Red
    $pushResult
    
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "Authentication Required" -ForegroundColor Yellow
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Two options to resolve:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Option A: Generate GitHub Token (Recommended)" -ForegroundColor Green
    Write-Host "1. Go to: https://github.com/settings/tokens" -ForegroundColor White
    Write-Host "2. Click 'Generate new token (classic)'" -ForegroundColor White
    Write-Host "3. Set note: 'OpenClaw-Auto-Push'" -ForegroundColor White
    Write-Host "4. Expiration: 90 days" -ForegroundColor White
    Write-Host "5. Select 'repo' scope" -ForegroundColor White
    Write-Host "6. Click 'Generate token'" -ForegroundColor White
    Write-Host "7. Copy the token and tell me" -ForegroundColor White
    Write-Host ""
    Write-Host "Option B: Use Git Credential Manager" -ForegroundColor Green
    Write-Host "1. A browser window may have opened" -ForegroundColor White
    Write-Host "2. Log in to GitHub if prompted" -ForegroundColor White
    Write-Host "3. Authorize the Git Credential Manager" -ForegroundColor White
    Write-Host "4. Try the push command again" -ForegroundColor White
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Script completed" -ForegroundColor Cyan
Pause