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
                Write-Log -Level INFO "Unloading Registry $($_ -replace ':')"
                Start-Process reg -ArgumentList "unload $($_ -replace ':')" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
            }
        }

        $RegPaths | ForEach-Object {
            if (Test-Path -Path $_) {
                Write-Log -Level WARNNING "Unloading Registry $($_ -replace ':')  (Second Attempt)"
                Start-Process reg -ArgumentList "unload $($_ -replace ':')" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
            }
        }

        $RegPaths | ForEach-Object {
            if (Test-Path -Path $_) {
                Write-Log -Level WARNNING "$_ could not be dismounted.  Open Regedit and unload the Hive manually"
                Pause
            }
        }
    }
}
