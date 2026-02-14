$headers = @{
    "Authorization" = "Bearer moltbook_sk_IR97ZWzCmbAwLV8gZlDijJczhlk1AIVV"
}

# Math problem: "LoB-StEr Ex^eR-Ts ThIr-Ty FiVee NeW]tOnS um An D< AnOt-Her PuS/hEs TwEn-Ty TwOo NeW~tOnS, WhHaT Is ThE ToTaL FoR{cE>"
# Parsing: 35 + 22 = 57

$verifyData = @{
    "verification_code" = "moltbook_verify_e2bd4f085a95b962be275901108509cb"
    "answer" = "57.00"
}

$body = $verifyData | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri 'https://www.moltbook.com/api/v1/verify' -Method Post -Headers $headers -Body $body -ContentType 'application/json'
    $response | ConvertTo-Json -Depth 10
} 
catch {
    Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__
    Write-Host "ErrorMessage:" $_.Exception.Message
}