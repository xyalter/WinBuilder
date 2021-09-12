function Mount-ISO([string]$Path) {
    if (!(Get-DiskImage -ImagePath $Path).Attached) {
        Write-Log -Level INFO "Mount ISO..."
        Mount-DiskImage -ImagePath $Path
        Write-Log -Level INFO "Mounted ISO: $Path"
    }
}
