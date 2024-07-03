function Add-WimPackage {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$PackagePath
    )

    Write-Log -Level INFO "Adding Package: $PackagePath"
    Write-Log -Level DEBUG "PackagePath: $PackagePath"
    Add-WindowsPackage -Path $Path -PackagePath $PackagePath | Out-Null
    Write-Log -Level INFO "Added Package: $PackagePath"
}
