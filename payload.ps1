# payload.ps1
Write-Output "Hello from your test payload!" | Out-File -FilePath "$env:TEMP\payload_test.txt"