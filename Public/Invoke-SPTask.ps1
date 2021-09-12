function Invoke-SPTask {
    [CmdletBinding(DefaultParameterSetName = "TaskName")]
    Param (
        [Parameter(ParameterSetName = "TaskName", Mandatory = $true, Position = 0)]
        [string]$TaskName,
        [Parameter(ParameterSetName = "TaskPath", Mandatory = $true, Position = 0)]
        [string]$TaskPath
    )

    $chosen = $PSCmdlet.ParameterSetName
    if ($chosen -eq "TaskName") {
        $TaskPath = "$ProjectRoot\tasks\$TaskName.json"
    }
    $content = Get-Content $TaskPath | ConvertFrom-Json

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
    Mount-WindowsImage -Path $MountPath -ImagePath $ImagePath -Index $ImageIndex | Out-Null

    Dism.exe /Image:$MountPath /Add-Driver /Driver:"$ProjectRoot\drivers\dell\serial\Win10" /Recurse
    # $content.Drivers | ForEach-Object {
    #     if ($_.EndsWith(".json")) {
    #         Add-WimDriver -Path $MountPath -JsonPath "$DriverRoot\$_"
    #     }
    #     else {
    #         Add-WimDriver -Path $MountPath -DriverPath "$DriverRoot\$_"
    #     }
    # }
    Dismount-WindowsImage -Path $MountPath -Save | Out-Null

    # Clean-Image
    $TempImagePath = "$TempDirectory\$(Get-Random).wim"
    Export-Image -SourceImagePath $ImagePath -DestinationImagePath $TempImagePath
    Move-Item -Force $TempImagePath $ImagePath
}
