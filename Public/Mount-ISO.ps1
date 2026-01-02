function Mount-ISO([string]$Path) {
    if (!(Get-DiskImage -ImagePath $Path).Attached) {
        Write-PSFMessage -Level Output -Message "Mount ISO..."
        Mount-DiskImage -ImagePath $Path
        Write-PSFMessage -Level Output -Message "Mounted ISO: $Path"
    }
}
