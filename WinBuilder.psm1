#===================================================================================================
#   Import Functions
#   https://github.com/RamblingCookieMonster/PSStackExchange/blob/master/PSStackExchange/PSStackExchange.psm1
#===================================================================================================

#===================================================================================================
#   Initialize PSFramework Logging
#===================================================================================================
# Import PSFramework if not already loaded
if (-not (Get-Module -Name PSFramework)) {
    Import-Module PSFramework -ErrorAction Stop
}

# Configure and enable console logging provider
Set-PSFLoggingProvider -Name console -InstanceName WinBuilderConsole -Enabled $true

# Get public and private function definition files.
$PublicFunctions  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$PrivateFunctions = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

# Dot source the files
foreach ($Import in @($PublicFunctions + $PrivateFunctions)) {
    Try {
        . $Import.FullName
    }
    Catch {
        Write-PSFMessage -Level Warning -Message "Failed to import function $($Import.FullName): $_" -ErrorRecord $_
    }
}

# Here I might...
    # Read in or create an initial config file and variable
    # Export Public functions ($Public.BaseName) for WIP modules
    # Set variables visible to the module and its functions only

Export-ModuleMember -Function $PublicFunctions.BaseName
