function Test-Admin {
    Write-Log -Level INFO "Check Administrator rights..."
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $result = $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    Write-Log -Level INFO "Administrator rights: $result"
    return $result
}
