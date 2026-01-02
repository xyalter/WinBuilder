function Mount-OfflineRegistry {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    #======================================================================================
    #	Mount-RegistryHives
    #======================================================================================
    if (($Path) -and (Test-Path "$Path" -ErrorAction SilentlyContinue)) {
        if (Test-Path "$Path\Users\Default\NTUser.dat") {
            Write-PSFMessage -Message "Loading Offline Registry Hive Default User"
            Start-Process reg -ArgumentList "load HKLM\OfflineDefaultUser $Path\Users\Default\NTUser.dat" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
        }
        if (Test-Path "$Path\Windows\System32\Config\DEFAULT") {
            Write-PSFMessage -Message "Loading Offline Registry Hive DEFAULT"
            Start-Process reg -ArgumentList "load HKLM\OfflineDefault $Path\Windows\System32\Config\DEFAULT" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
        }
        if (Test-Path "$Path\Windows\System32\Config\SOFTWARE") {
            Write-PSFMessage -Message "Loading Offline Registry Hive SOFTWARE"
            Start-Process reg -ArgumentList "load HKLM\OfflineSoftware $Path\Windows\System32\Config\SOFTWARE" -Wait -WindowStyle Hidden -ErrorAction Stop
        }
        if (Test-Path "$Path\Windows\System32\Config\SYSTEM") {
            Write-PSFMessage -Message "Loading Offline Registry Hive SYSTEM"
            Start-Process reg -ArgumentList "load HKLM\OfflineSystem $Path\Windows\System32\Config\SYSTEM" -Wait -WindowStyle Hidden -ErrorAction Stop
        }
    }
}
