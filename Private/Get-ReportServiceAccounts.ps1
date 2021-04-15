function Get-ReportServiceAccounts {
    [cmdletBinding()]
    param(
        [Array] $AllUsers,
        [System.Collections.IDictionary]$Cache
    )
    $Statistics = [ordered] @{
        Summary         = [ordered] @{
            'Accounts total'                              = 0
            'Accounts disabled'                           = 0
            'Accounts enabled'                            = 0
            'Manager missing'                             = 0
            'Manager disabled'                            = 0
            'Manager enabled'                             = 0
            'Manager account logged in over 180 days ago' = 0
            'Manager account logged in over 90 days ago'  = 0
            'Manager never logged in'                     = 0
            'Accounts password over 360 Days'             = 0
            'Accounts password never set'                 = 0
            'Accounts logged in over 180 days ago'        = 0
            'Accounts logged in over 90 days ago'         = 0
            'Accounts never logged in'                    = 0
            'Accounts password not required'              = 0
            'Accounts password expired'                   = 0
            'Accounts password never expires'             = 0
            'Accounts being service account'              = 0
            'Accounts not service account'                = 0
        }
        SummaryEnabled  = [ordered] @{}
        SummaryDisabled = [ordered] @{}
        All             = [ordered] @{
            'Potentially Missing' = [ordered] @{}
        }
        Enabled         = [ordered] @{
            'Potentially Missing' = [ordered] @{}
        }
        Disabled        = [ordered] @{
            'Potentially Missing' = [ordered] @{}
        }
    }
    $Summary = [ordered] @{
        All      = [ordered] @{
            'Potentially Missing' = [System.Collections.Generic.List[PSCustomObject]]::new()
        }
        Enabled  = [ordered] @{   }
        Disabled = [ordered] @{   }
    }
    $Users = Get-ServiceAccount -Cache $Cache -AllUsers $AllUsers
    foreach ($User in $Users) {
        if (-not $Summary['All'][$User.Level0]) {
            $Summary['All'][$User.Level0] = [System.Collections.Generic.List[PSCustomObject]]::new()
            $Statistics['All'][$User.Level0] = [ordered] @{}
        }
        if (-not $Summary['Disabled'][$User.Level0]) {
            $Summary['Disabled'][$User.Level0] = [System.Collections.Generic.List[PSCustomObject]]::new()
            $Statistics['Disabled'][$User.Level0] = [ordered] @{}
        }
        if (-not $Summary['Enabled'][$User.Level0]) {
            $Summary['Enabled'][$User.Level0] = [System.Collections.Generic.List[PSCustomObject]]::new()
            $Statistics['Enabled'][$User.Level0] = [ordered] @{}
        }
        $Summary['All'][$User.Level0].add($User)
        if ($User.ObjectClass -eq 'user' -and $User.IsMissing -eq $true) {
            $Summary['All']['Potentially missing'].add($User)
            Set-Statistics -Statistics $Statistics['All']['Potentially Missing'] -User $User
        }
        if ($User.Enabled -eq $false) {
            $Summary['Disabled'][$User.Level0].add($User)
        } else {
            $Summary['Enabled'][$User.Level0].add($User)
        }
        Set-Statistics -Statistics $Statistics['All'][$User.Level0] -User $User

        # Summary
        Set-Statistics -Statistics $Statistics['Summary'] -User $User
        # Enabled / Disabled
        if ($User.Enabled -eq $false) {
            Set-Statistics -Statistics $Statistics['SummaryDisabled'] -User $User
            Set-Statistics -Statistics $Statistics['Disabled'][$User.Level0] -User $User
            Set-Statistics -Statistics $Statistics['Disabled']['Potentially Missing'] -User $User
        } else {
            Set-Statistics -Statistics $Statistics['SummaryEnabled'] -User $User
            Set-Statistics -Statistics $Statistics['Enabled'][$User.Level0] -User $User
            Set-Statistics -Statistics $Statistics['Enabled']['Potentially Missing'] -User $User
        }
    }
    @{
        Summary    = $Summary
        Statistics = $Statistics
        Objects    = $Users
    }
}