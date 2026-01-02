function Import-OfflineRegistry {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [array]$RegFiles
    )

    $MountDirectory = Get-Item -Path $Path

    #======================================================================================
    #	Mount-RegistryHives
    #======================================================================================
    Mount-OfflineRegistry -Path $Path

    #======================================================================================
    #	Add-RegistryFiles
    #======================================================================================
    $TempDirectory = "$env:TEMP\$(Get-Random)"
    if (!(Test-Path $TempDirectory)) { New-Item -Path "$TempDirectory" -ItemType Directory -Force | Out-Null }

    foreach ($RegFile in $RegFiles) {
        $ImportFile = $RegFile.FullName

        if ($MountDirectory) {
            $RegContent = Get-Content -Path $ImportFile
            $ImportFile = "$TempDirectory\$($RegFile.BaseName).reg"

            $RegContent = $RegContent -replace 'HKEY_USERS\\DEFAULT', 'HKEY_LOCAL_MACHINE\OfflineDefaultUser'
            $RegContent = $RegContent -replace 'HKEY_LOCAL_MACHINE\\SOFTWARE', 'HKEY_LOCAL_MACHINE\OfflineSoftware'
            $RegContent = $RegContent -replace 'HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet', 'HKEY_LOCAL_MACHINE\OfflineSystem\ControlSet001'
            $RegContent = $RegContent -replace 'HKEY_LOCAL_MACHINE\\SYSTEM', 'HKEY_LOCAL_MACHINE\OfflineSystem'
            $RegContent = $RegContent -replace 'HKEY_USERS\\.DEFAULT', 'HKEY_LOCAL_MACHINE\OfflineDefault'
            $RegContent | Set-Content -Path $ImportFile -Force

            $RawContent = Get-Content -Raw $ImportFile
            $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
            [System.IO.File]::WriteAllLines($ImportFile, $RawContent, $Utf8NoBomEncoding)
        }

        # Write-Information "Import Reg: $ImportFile"
        Write-PSFMessage -Level Output -Message "Import Reg: $ImportFile"
        $ShowRegContent = $false
        if ($ShowRegContent) {
            $TempContent = @()
            $TempContent = Get-Content -Path $ImportFile
            foreach ($Line in $TempContent) {
                Write-PSFMessage -Level Debug -Message "$Line"
            }
        }
        Start-Process reg -ArgumentList ('import', "`"$ImportFile`"") -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
    }
    
    #======================================================================================
    #	Remove-TempDirectory
    #======================================================================================
    if ($MountDirectory) {
        if (Test-Path $TempDirectory) { Remove-Item -Path "$TempDirectory" -Recurse -Force | Out-Null }
    }

    #======================================================================================
    #	Dismount-RegistryHives
    #======================================================================================
    Dismount-OfflineRegistry -Path $Path
}
