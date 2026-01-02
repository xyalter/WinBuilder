function Remove-WimAppxPackage {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$PackageName
    )

    Get-AppxProvisionedPackage -Path $Path | Where-Object {
        $_.PackageName.startsWith($PackageName)
    } | ForEach-Object {
        Write-PSFMessage -Level Output -Message "Removing Appx: $($_.PackageName)"
        Remove-AppxProvisionedPackage -Path $Path -PackageName $_.PackageName | Out-Null
        Write-PSFMessage -Level Output -Message "Removed Appx: $($_.PackageName)"
    }
}
