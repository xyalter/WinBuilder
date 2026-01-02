function Add-WimPackage {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$PackagePath
    )

    Write-PSFMessage -Level Output -Message "Adding Package: $PackagePath"
    Write-PSFMessage -Message "PackagePath: $PackagePath"
    Add-WindowsPackage -Path $Path -PackagePath $PackagePath | Out-Null
    Write-PSFMessage -Level Output -Message "Added Package: $PackagePath"
}
