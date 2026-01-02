function Dismount-ISO([string]$Path) {
    if ((Get-DiskImage -ImagePath $Path).Attached) {
        Write-PSFMessage -Level Output -Message "Dismount ISO..."
        Dismount-DiskImage -ImagePath $Path
        Write-PSFMessage -Level Output -Message "Dismounted ISO: $Path"
    }
}
