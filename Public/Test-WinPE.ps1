function Test-WinPE {
    Write-PSFMessage -Level Output -Message "Check run in WinPE..."
    $result = Test-Path "X:\Windows\system32"
    Write-PSFMessage -Level Output -Message "Run in WinPE: $result"
    return $result
}
