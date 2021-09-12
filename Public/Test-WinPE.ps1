function Test-WinPE { 
    Write-Log -Level INFO "Check run in WinPE..."
    $result = Test-Path "X:\Windows\system32"
    Write-Log -Level INFO "Run in WinPE: $result"
    return $result
}
