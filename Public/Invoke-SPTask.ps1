function Invoke-SPTask {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [string]$Path
    )

    $InformationPreference = "Continue"
    if (!(Test-Admin)) { throw "Administrator rights are required!" }
    if (!(Test-Path $Path)) { throw "Task file not found!" }

    $ProjectRoot = (Get-Item -Path $Path).Directory.Parent.FullName
    $DriverRoot = $ProjectRoot + '\drivers'

    $content = Get-Content $Path | ConvertFrom-Json

    $TempDirectory = "$ProjectRoot\build\$(Get-Random)"
    if (!(Test-Path $TempDirectory)) { New-Item -Path "$TempDirectory" -ItemType Directory -Force | Out-Null }

    #======================================================================================
    #	Import-Image
    #======================================================================================
    $ImagePath = "$TempDirectory\WEPE64.wim"
    $ImageIndex = $content.ImageIndex
    Export-Image "$ProjectRoot\wim\$($content.ImagePath)" $ImageIndex $ImagePath

    # Create mount directory
    $MountPath = "$TempDirectory\mount"
    if (!(Test-Path $MountPath)) { New-Item -Path "$MountPath" -ItemType Directory -Force | Out-Null }

    #======================================================================================
    #	Edit-SPImage
    #======================================================================================
    try {
        Write-PSFMessage -Level Output -Message "Mount Image..."
        Mount-WindowsImage -Path $MountPath -ImagePath $ImagePath -Index $ImageIndex | Out-Null
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

        Repair-WindowsImage -Path $MountPath -StartComponentCleanup -ResetBase | Out-Null

        # Dism.exe /Image:$MountPath /Add-Driver /Driver:"$ProjectRoot\drivers\dell\serial\Win10" /Recurse
    }
    catch {
        Write-PSFMessage -Level Warning -Message "Failed to process image: $_" -ErrorRecord $_
        throw $_
    }
    finally {
        Write-PSFMessage -Level Output -Message "Dismount Image..."
        Dismount-WindowsImage -Path $MountPath -Save | Out-Null
        Write-PSFMessage -Level Output -Message "Dismounted Image: $MountPath"
    }

    # Clean-Image
    $TempImagePath = "$TempDirectory\$(Get-Random).wim"
    Export-Image -SourceImagePath $ImagePath -DestinationImagePath $TempImagePath
    Move-Item -Force $TempImagePath $ImagePath
}
