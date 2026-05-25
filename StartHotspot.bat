<# : batch portion
@echo off
setlocal
net session >nul 2>&1
if %errorLevel% == 0 ( goto :runScript ) else (
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
:runScript
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Content '%~f0' | Out-String | Invoke-Expression"
exit /b
#>

# --- PANGMALAKASANG MAIN SCREEN ---
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "             MOBILE HOTSPOT BROWNOUT MONITOR             " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " * Mode: Continuous System Monitoring" -ForegroundColor Gray
Write-Host " * Normal Interval: Checking every minute" -ForegroundColor Green
Write-Host " * Outage Interval: Checking every 5 seconds" -ForegroundColor Red
Write-Host " * Press CTRL+C inside this window to exit cleanly." -ForegroundColor DarkGray
Write-Host "=========================================================`n" -ForegroundColor Cyan

while ($true) {
    $time = "[$(Get-Date -Format "hh:mm:ss tt")]"

    # Get Power and Battery Status
    $battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
    $powerStatus = "Desktop PC (AC Power)"
    
    if ($null -ne $battery) {
        # BatteryStatus: 1 = Discharging (On Battery), 2 = AC Power (Plugged In/Charging)
        $statusType = $battery.BatteryStatus
        $percent = $battery.EstimatedChargeRemaining
        
        if ($statusType -eq 1) {
            $powerStatus = "Battery ($percent%)"
        } else {
            $powerStatus = "Plugged In ($percent%)"
        }
    }

    # 1. Ping Lacson Check
    $hasInternet = [System.Net.NetworkInformation.Ping]::new().Send("8.8.8.8", 1000).Status -eq "Success"

    if ($hasInternet) {
        $profile = [Windows.Networking.Connectivity.NetworkInformation, Windows.Networking.Connectivity, ContentType=WindowsRuntime]::GetInternetConnectionProfile()
        $tether = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager, Windows.Networking.NetworkOperators, ContentType=WindowsRuntime]::CreateFromConnectionProfile($profile)

        if ($null -ne $tether) {
            # 2. Check and Turn On Hotspot. for InterfaceType conditions 71 is Wifi, 6 is Ethernet kase why not
            if ($tether.TetheringOperationalState -ne 1) {
                # Gather Connection Metadata
                $netName = $profile.ProfileName
                $netType = "Unknown"
                $bandInfo = ""

                if ($profile.NetworkAdapter.IanaInterfaceType -eq 71) { 
                    $netType = "WiFi"
                    $wlanInfo = netsh wlan show interfaces
                    $channel = ($wlanInfo | Select-String "Channel\s*:\s*(\d+)").Matches.Groups[1].Value
                    if ($channel) {
                        if ([int]$channel -le 14) { $bandInfo = " [2.4 GHz]" } else { $bandInfo = " [5 GHz]" }
                    }
                }
                elseif ($profile.NetworkAdapter.IanaInterfaceType -eq 6) { 
                    $netType = "Ethernet" 
                }

                # Retrieve Local IPv4 Address
                $ipHostInfo = [System.Net.Dns]::GetHostAddresses("") | Where-Object { $_.AddressFamily -eq 'InterNetwork' }
                $localIP = ($ipHostInfo | Select-Object -First 1).IPAddressToString

                Write-Host "$time Power: $powerStatus | Internet recovered via $netType ($netName)$bandInfo | IP: $localIP | Starting hotspot..." -ForegroundColor Yellow
                [void]$tether.StartTetheringAsync()
                Start-Sleep -Seconds 2
            }

            # 3. Check and Disable Power Saving
            if ([Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager]::IsNoConnectionsTimeoutEnabled()) {
                [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager]::DisableNoConnectionsTimeout()
                Write-Host "$time Power: $powerStatus | Hotspot active. Power saving has been disabled." -ForegroundColor Green
            } else {
                Write-Host "$time Power: $powerStatus | Hotspot is running stably (Power saving already disabled)." -ForegroundColor Green
            }
        }
        Start-Sleep -Seconds 60  # Relaxed check when internet is stable, change to lower or higher kung trip mas realtime checking, makimemory nga lang
    } 
    else {
        # Highlight in Yellow if it's on Battery during a brownout for alert
        $powerColor = if ($powerStatus -like "Battery*") { "Yellow" } else { "Red" }
        Write-Host "$time Power: $powerStatus | NO INTERNET (Router offline). Retrying in 5 seconds..." -ForegroundColor $powerColor
        Start-Sleep -Seconds 5   # Fast check during a brownout outage
    }
}