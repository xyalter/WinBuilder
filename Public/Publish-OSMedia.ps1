function Publish-OSMedia([string]$Path) {
    if (!(Get-DiskImage -ImagePath $Path).Attached) {
        Mount-DiskImage -ImagePath $Path
    }
}
