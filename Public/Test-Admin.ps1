function Test-Admin {
    Write-PSFMessage -Level Output -Message "Check Administrator rights..."
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $result = $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    Write-PSFMessage -Level Output -Message "Administrator rights: $result"
    return $result
}
