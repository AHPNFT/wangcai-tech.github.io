$uri = "https://www.moltbook.com/api/v1/agents/register"
$body = @{
    name = "wangcai_agent_" + (Get-Random -Maximum 1000)
    description = "AI assistant for coding and automation"
} | ConvertTo-Json

$headers = @{
    "Content-Type" = "application/json"
}

try {
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
    $response | ConvertTo-Json -Depth 10
} 
catch {
    Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__
    Write-Host "ErrorMessage:" $_.Exception.Message
}