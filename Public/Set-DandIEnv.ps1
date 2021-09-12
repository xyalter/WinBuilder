function Set-DandIEnv {
    if (Test-WinPE) { Write-Out 'Running in WinPE, ignore DandISetEnv.'; return }
    $KitsRoot='C:\Program Files (x86)\Windows Kits\10'
    $env:DandIRoot=$KitsRoot + '\Assessment and Deployment Kit\Deployment Tools'
    # C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\DandISetEnv.bat
    cmd.exe /c "call `"%DandIRoot%\DandISetEnv.bat`" && set > %temp%\vcvars.txt"
    Get-Content "$env:temp\vcvars.txt" | Foreach-Object {
        if ($_ -match "^(.*?)=(.*)$") {
            Set-Content "env:\$($matches[1])" $matches[2]
        }
    }
}
