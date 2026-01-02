function Add-WimDriver {
    [CmdletBinding()]
    Param (
        [Parameter(ParameterSetName = "DriverPath", Mandatory = $true)]
        [Parameter(ParameterSetName = "JsonPath", Mandatory = $true)]
        [string]$Path,
        [Parameter(ParameterSetName = "DriverPath", Mandatory = $true)]
        [string]$DriverPath,
        [Parameter(ParameterSetName = "JsonPath", Mandatory = $true)]
        [string]$JsonPath
    )

    $chosen = $PSCmdlet.ParameterSetName
    if ($chosen -eq "JsonPath") {
        $content = Get-Content $JsonPath | ConvertFrom-Json
        $content.Drivers | ForEach-Object {
            Add-WimDriver -Path $Path -DriverPath "$((Get-Item $JsonPath).DirectoryName)\$_"
        }
    }
    else {
        Write-PSFMessage -Level Output -Message "Adding Driver: $DriverPath"
        if ($DriverPath.EndsWith(".inf") -OR $DriverPath.EndsWith(".INF")) {
            Add-WindowsDriver -Path $Path -Driver $DriverPath 1>$null
        } else {
            Add-WindowsDriver -Path $Path -Driver $DriverPath -Recurse 1>$null
        }
        Write-PSFMessage -Level Output -Message "Added Driver: $DriverPath"
    }
}
