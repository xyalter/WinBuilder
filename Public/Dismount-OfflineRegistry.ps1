function Dismount-OfflineRegistry {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    #======================================================================================
    #	Dismount-RegistryHives
    #======================================================================================
    if (($Path) -and (Test-Path "$Path" -ErrorAction SilentlyContinue)) {
        $RegPaths = @(
            'HKLM:\OfflineDefaultUser',
            'HKLM:\OfflineDefault',
            'HKLM:\OfflineSoftware',
            'HKLM:\OfflineSystem'
        )

        $RegPaths | ForEach-Object {
            if (Test-Path -Path $_) {
                Write-PSFMessage -Level Output -Message "Unloading Registry $($_ -replace ':')"
                Start-Process reg -ArgumentList "unload $($_ -replace ':')" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
            }
        }

        $RegPaths | ForEach-Object {
            if (Test-Path -Path $_) {
                Write-PSFMessage -Level Warning -Message "Unloading Registry $($_ -replace ':')  (Second Attempt)"
                Start-Process reg -ArgumentList "unload $($_ -replace ':')" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
            }
        }

        $RegPaths | ForEach-Object {
            if (Test-Path -Path $_) {
                Write-PSFMessage -Level Warning -Message "$_ could not be dismounted.  Open Regedit and unload the Hive manually"
                Pause
            }
        }
    }
}
