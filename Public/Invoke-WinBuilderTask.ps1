function Invoke-WinBuilderTask {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [string]$Path
    )

    # PSFramework logging is initialized in WinBuilder.psm1
    Set-DandIEnv
    if (!(Test-Admin)) { throw "Administrator rights are required!" }
    if (!(Test-Path $Path)) { throw "Task file not found!" }

    $ProjectRoot = (Get-Item -Path $Path).Directory.Parent.FullName
    $DriverRoot = $ProjectRoot + '\drivers'
    $RegisteryRoot = $ProjectRoot + '\registries'
    $PackageRoot = $ProjectRoot + '\packages'

    $content = Get-Content $Path | ConvertFrom-Json

    $TempDirectory = "$ProjectRoot\build\$(Get-Random)"
    if (!(Test-Path $TempDirectory)) { New-Item -Path "$TempDirectory" -ItemType Directory -Force | Out-Null }

    # Configure file logging to build directory
    $LogFileName = "WinBuilder_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    $LogFilePath = Join-Path $TempDirectory $LogFileName
    Set-PSFLoggingProvider -Name logfile -InstanceName WinBuilderFile -FilePath $LogFilePath -Enabled $true

    #======================================================================================
    #   Import-Image
    #======================================================================================
    $ISOPath = "$ProjectRoot\iso\$($content.ISO)"
    try {
        if (!(Test-Path $ISOPath)) { throw "ISO file not found!`nISOPath:$ISOPath" }
        $DevicePath = (Mount-ISO -Path $ISOPath).DevicePath
        $Letter = (Get-DiskImage -DevicePath $DevicePath | Get-Volume).DriveLetter
        $IsoLabel = (Get-DiskImage -DevicePath $DevicePath | Get-Volume).FileSystemLabel

        # Create media directory
        $MediaPath = "$TempDirectory\media"
        if (!(Test-Path $MediaPath)) { New-Item -Path "$MediaPath" -ItemType Directory -Force | Out-Null }
        Copy-Item -Path "${Letter}:\*" -Destination "${MediaPath}" -Exclude @("boot.wim", "install.wim") -Recurse

        # boot.wim
        $ImagesInfo = Get-ImageFiles -DriveLetter $Letter -Include ("boot.wim") | Sort-Object -Property ImageIndex
        $ImagePath = "$TempDirectory\boot.wim"
        if (Test-Path $ImagePath) { Remove-Item -Force $ImagePath }
        $ImagesInfo | ForEach-Object {
            Export-Image $_.ImagePath $_.ImageIndex $ImagePath
        }

        # install.wim
        $ImagesInfo = Get-ImageFiles -DriveLetter $Letter -Include install.wim, install.esd
        $ImagePath = "$TempDirectory\install.wim"
        if (Test-Path $ImagePath) { Remove-Item -Force $ImagePath }
        $ImagesInfo |  Where-Object { $content.Editions -match $_.EditionId } | ForEach-Object {
            Export-Image $_.ImagePath $_.ImageIndex $ImagePath
        }
    }
    catch {
        Write-PSFMessage -Level Warning -Message $_ -ErrorRecord $_
        throw $_
    }
    finally {
        $null = Dismount-ISO -Path $ISOPath
    }

    # Create mount directory
    $MountPath = "$TempDirectory\mount"
    if (!(Test-Path $MountPath)) { New-Item -Path "$MountPath" -ItemType Directory -Force | Out-Null }

    #======================================================================================
    #   Edit-BootImage
    #======================================================================================
    $ImagePath = "$TempDirectory\boot.wim"
    Get-WindowsImage -ImagePath $ImagePath | ForEach-Object {
        $WimImageInfo = $_ | Select-Object -Property *
        $WimImageArchitecture = $WimImageInfo.Architecture
        Write-PSFMessage -Message "WimImageInfo: $($_.Architecture)"
        Write-PSFMessage -Message "WimImageInfo: $WimImageInfo"
        Write-PSFMessage -Message "Architecture: $WimImageArchitecture"
        if ($WimImageArchitecture -eq '0') { $WimImageArchitecture = 'x86' }
        if ($WimImageArchitecture -eq '6') { $WimImageArchitecture = 'ia64' }
        if ($WimImageArchitecture -eq '9') { $WimImageArchitecture = 'x64' }
        if ($WimImageArchitecture -eq '12') { $WimImageArchitecture = 'x64 ARM' }
        try {
            Write-PSFMessage -Level Output -Message "Mount Image..."
            Mount-WindowsImage -Path $MountPath -ImagePath $_.ImagePath -Index $_.ImageIndex | Out-Null
            Write-PSFMessage -Level Output -Message "Mounted Image: $MountPath"
            # Get-WindowsPackage -Path $MountPath

            #======================================================================================
            #   Add-Drivers
            #======================================================================================
            $content.BootDrivers | ForEach-Object {
                if ($_.EndsWith(".json")) {
                    Add-WimDriver -Path $MountPath -JsonPath "$DriverRoot\$_"
                }
                else {
                    Add-WimDriver -Path $MountPath -DriverPath "$DriverRoot\$_"
                }
            }

            #======================================================================================
            #   Add-Packages
            #======================================================================================
            $content.BootPackages | ForEach-Object {
                if ($_.EndsWith(".msu") -or $_.EndsWith(".cab")) {
                    $PackagePath = "$PackageRoot\$_"
                    Add-WimPackage -Path $MountPath -PackagePath $PackagePath
                    # Repair-WindowsImage -Path $MountPath -StartComponentCleanup -ResetBase | Out-Null
                    # Get-WindowsPackage -Path $MountPath
                }
                else {
                    $PackagePath = "$env:WinPERoot\$($content.Architecture)\WinPE_OCs\$_.cab"
                    Add-WimPackage -Path $MountPath -PackagePath $PackagePath
                }
            }

            Repair-WindowsImage -Path $MountPath -StartComponentCleanup -ResetBase | Out-Null
        }
        catch {
            Write-PSFMessage -Level Warning -Message $_ -ErrorRecord $_
            throw $_
        }
        finally {
            Write-PSFMessage -Level Output -Message "Dismount Image..."
            Dismount-WindowsImage -Path $MountPath -Save | Out-Null
            Write-PSFMessage -Level Output -Message "Dismounted Image: $MountPath"
        }
    }
    $TempImagePath = "$TempDirectory\$(Get-Random).wim"
    Export-Image -SourceImagePath $ImagePath -DestinationImagePath $TempImagePath
    Move-Item -Force $TempImagePath $ImagePath
    # throw "test"

    #======================================================================================
    #   Edit-MainImage
    #======================================================================================
    $ImagePath = "$TempDirectory\install.wim"
    $ImagesInfo = Get-WindowsImage -ImagePath $ImagePath | Sort-Object -Property ImageIndex | ForEach-Object {
        Get-WindowsImage -ImagePath $_.ImagePath -Index $_.ImageIndex
    }
    $ImagesInfo | ForEach-Object {
        try {
            #======================================================================================
            #   Mount-MainImage
            #======================================================================================
            Write-PSFMessage -Level Output -Message "Mount Image..."
            Mount-WindowsImage -Path $MountPath -ImagePath $_.ImagePath -Index $_.ImageIndex | Out-Null
            Write-PSFMessage -Level Output -Message "Mounted Image: $MountPath"

            #======================================================================================
            #   Add-Drivers
            #======================================================================================
            $content.Drivers | ForEach-Object {
                if ($_.EndsWith(".json")) {
                    Add-WimDriver -Path $MountPath -JsonPath "$DriverRoot\$_"
                }
                else {
                    Add-WimDriver -Path $MountPath -DriverPath "$DriverRoot\$_"
                }
            }

            #======================================================================================
            #   Add-Registries
            #======================================================================================
            $RegFiles = $content.Registries | ForEach-Object { Get-Item "$RegisteryRoot\$_" }
            Import-OfflineRegistry -Path $MountPath -RegFiles $RegFiles

            #======================================================================================
            #   Deploy-AppxPackages
            #======================================================================================
            $content.AppxPackages | ForEach-Object {
                if ($_.action -eq "remove") {
                    Remove-WimAppxPackage -Path $MountPath -PackageName $_.name
                }
            }

            #======================================================================================
            #   Add-Packages
            #======================================================================================
            $ProvisioningPackagesPath = "$MountPath\Windows\Provisioning\Packages"
            if (!(Test-Path $ProvisioningPackagesPath)) {
                New-Item -Path $ProvisioningPackagesPath -ItemType Directory -Force | Out-Null
            }
            $content.Packages | ForEach-Object {
                # Dism /Image=$MountPath /Add-ProvisioningPackage /PackagePath:"$PackageRoot\$_"
                Copy-Item -Path "$PackageRoot\$_" -Destination $ProvisioningPackagesPath -Force
                Write-PSFMessage -Message "Copied ProvisioningPackage: $_"
            }

            Repair-WindowsImage -Path $MountPath -StartComponentCleanup -ResetBase | Out-Null
        }
        catch {
            Write-PSFMessage -Level Warning -Message $_ -ErrorRecord $_
            throw $_
        }
        finally {
            #======================================================================================
            #   Save-Image
            #======================================================================================
            # cmd /c pause
            Write-PSFMessage -Level Output -Message "Dismount Image..."
            Dismount-WindowsImage -Path $MountPath -Save | Out-Null
            Write-PSFMessage -Level Output -Message "Dismounted Image: $MountPath"
        }
    }

    #======================================================================================
    #   Clean-Image
    #======================================================================================
    $TempImagePath = "$TempDirectory\$(Get-Random).wim"
    Export-Image -SourceImagePath $ImagePath -DestinationImagePath $TempImagePath
    Move-Item -Force $TempImagePath $ImagePath

    Move-Item -Path "$TempDirectory\boot.wim" -Destination "$MediaPath\sources\"
    Move-Item -Path "$TempDirectory\install.wim" -Destination "$MediaPath\sources\"

    #======================================================================================
    #   Add-Unattend
    #======================================================================================
    if ($content.PSobject.Properties.name -match "Unattend") {
        # $DestDir = "$MountPath\Windows\Panther\Unattend"
        # if (!(Test-Path $DestDir)) { New-Item -Path $DestDir -ItemType Directory -Force | Out-Null }
        # Copy-Item -Path "$ProjectRoot\configs\$($content.Unattend)" -Destination $DestDir\Unattend.xml
        Copy-Item -Path "$ProjectRoot\configs\$($content.Unattend)" -Destination $MediaPath\AutoUnattend.xml
    }

    #======================================================================================
    #   Add-OEM-Files
    #======================================================================================
    if ($content.PSobject.Properties.name -match "OEM") {
        $OemRoot = $ProjectRoot + '\oem'
        $OemDirectory = "$MediaPath\sources\`$OEM`$"
        if (!(Test-Path $OemDirectory)) { New-Item -Path $OemDirectory -ItemType Directory -Force | Out-Null }
        $content.OEM | ForEach-Object {
            Copy-Item -Path "$OemRoot\$($_.action)\*" -Destination "$OemDirectory\" -Recurse -Force
            $appPath = $_.path
            if ($_.action -eq "audit_install") {
                $_.packages | ForEach-Object {
                    Copy-Item -Path "$PackageRoot\$_.exe" -Destination "$OemDirectory\`$`$\OEM\$appPath"
                }
            }
            if ($_.action -eq "oobe_install") {
                $_.packages | ForEach-Object {
                    Copy-Item -Path "$PackageRoot\$_.exe" -Destination "$OemDirectory\`$`$\OEM\$appPath"
                }
            }
        }
    }

    $orderFile = Get-Content "$((Get-Item $PSScriptRoot).Parent.FullName)\Private\bootOrder.txt"
    $orderFile | Out-File "$TempDirectory\bootOrder.txt" -Encoding ascii

    $bootdata = '2#p0,e,b"{0}"#pEF,e,b"{1}"' -f `
        "$MediaPath\boot\etfsboot.com", `
        "$MediaPath\efi\microsoft\boot\efisys.bin"

    # -yo"$TempDirectory\bootOrder.txt" `
    oscdimg -bootdata:"$bootdata" `
        -u2 -udfver102 -l"$IsoLabel" -m -o `
        "$MediaPath" "$TempDirectory\win.iso"

    if ($content.PSobject.Properties.name -match "Output") {
        Move-Item -Path "$TempDirectory\win.iso" -Destination $content.Output -Force
    }
}
