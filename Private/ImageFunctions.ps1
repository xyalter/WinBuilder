function Get-ImageFiles {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [string]$DriveLetter,
        [Parameter(Mandatory)]
        [string[]]$Include
    )

    $ImageFile = Get-ChildItem "${DriveLetter}:\sources\*" -Include $Include | Select-Object -First 1
    $ImageFile | ForEach-Object {
        Get-WindowsImage -ImagePath $_ | Sort-Object -Property ImageIndex | ForEach-Object {
            Get-WindowsImage -ImagePath $_.ImagePath -Index $_.ImageIndex
        }
    }
}

function Export-Image {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, Position = 0)]
        [string]$SourceImagePath,
        [Parameter(ParameterSetName = "B", Mandatory, Position = 1)]
        [UInt32]$SourceIndex,
        [Parameter(ParameterSetName = "A", Mandatory, Position = 1)]
        [Parameter(ParameterSetName = "B", Mandatory, Position = 2)]
        [string]$DestinationImagePath 
    )

    if ($SourceIndex -eq 0) {
        Get-WindowsImage -ImagePath $SourceImagePath | Sort-Object -Property ImageIndex | ForEach-Object {
            Export-Image $SourceImagePath $_.ImageIndex $DestinationImagePath
        }
    }
    else {
        Write-PSFMessage -Level Output -Message "Export Image..."
        Export-WindowsImage -SourceImagePath $SourceImagePath -SourceIndex $SourceIndex `
            -DestinationImagePath $DestinationImagePath -CompressionType max | Out-Null
        Write-PSFMessage -Level Output -Message "Exported Image: $SourceImagePath $SourceIndex"
    }
}
