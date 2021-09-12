function Dismount-ISO([string]$Path) {
    if ((Get-DiskImage -ImagePath $Path).Attached) {
        Write-Log -Level INFO "Dismount ISO..."
        Dismount-DiskImage -ImagePath $Path
        Write-Log -Level INFO "Dismounted ISO: $Path"
    }
}
