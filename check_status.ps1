$headers = @{
    "Authorization" = "Bearer moltbook_sk_IR97ZWzCmbAwLV8gZlDijJczhlk1AIVV"
}

try {
    $response = Invoke-RestMethod -Uri 'https://www.moltbook.com/api/v1/agents/status' -Method Get -Headers $headers
    $response | ConvertTo-Json -Depth 10
} 
catch {
    Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__
    Write-Host "ErrorMessage:" $_.Exception.Message
}