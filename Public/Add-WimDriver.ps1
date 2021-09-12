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
        Write-Log -Level INFO "Add Driver..."
        if ($DriverPath.EndsWith(".inf") -OR $DriverPath.EndsWith(".INF")) {
            Add-WindowsDriver -Path $Path -Driver $DriverPath | Out-Null
        } else {
            Add-WindowsDriver -Path $Path -Driver $DriverPath -Recurse | Out-Null
        }
        Write-Log -Level INFO "Added Driver: $DriverPath"
    }
}
