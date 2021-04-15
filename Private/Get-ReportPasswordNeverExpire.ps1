function Get-ReportPasswordNeverExpire {
    [cmdletBinding()]
    param(
        [Array] $AllUsers,
        [System.Collections.IDictionary]$Cache
    )
    $Today = Get-Date
    $GroupMembersCache = @{}
    $Groups = 'WO_SVC Allow Interactive RDP login', 'WO_SVC Deny Interactive RDP login'
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
        All             = [ordered] @{}
        Enabled         = [ordered] @{}
        Disabled        = [ordered] @{}
    }
    $Summary = [ordered] @{
        Summary  = [ordered]@{}
        All      = [ordered]@{}
        Enabled  = [ordered] @{}
        Disabled = [ordered] @{}
    }

    $Exclusions = [ordered] @{
        SamAccountName = 'HealthMailbox*'
    }
    $FindUsers = foreach ($U in $AllUsers) {
        $Excluded = $false
        foreach ($Exclusion in $Exclusions.Keys) {
            if ($U.$Exclusion -like $Exclusions[$Exclusion]) {
                $Excluded = $true
                break
            }
        }
        if ($Excluded) {
            continue
        }
        # Lets return what we found
        if ($U.PasswordNeverExpires -eq $true) {
            $U
        }
    }

    foreach ($Group in $Groups) {
        $GroupMembers = Get-WinADGroupMember -Identity $Group
        foreach ($User in $GroupMembers) {
            if ($User.Type -eq 'user') {
                # Lets cache all users from groups
                $GroupMembersCache[$User.DistinguishedName] = $Cache[$User.DistinguishedName]
                # Lets find details about user
                #Get-PreparedUserInformation -User $Cache[$User.DistinguishedName] -Cache $Cache -Group $Group
            }
        }
    }


    $Users = @(
        foreach ($User in $FindUsers) {
            if ($GroupMembersCache[$User.DistinguishedName]) {
                Get-PreparedUserInformation -User $User -Cache $Cache -Group 'Group' -Today $Today
            } else {
                Get-PreparedUserInformation -User $User -Cache $Cache -Today $Today
            }
        }
    )

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

        if ($User.Enabled -eq $false) {
            $Summary['Disabled'][$User.Level0].add($User)
            # $Statistics['All'][$User.Region]['Account disabled']++
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
        } else {
            Set-Statistics -Statistics $Statistics['SummaryEnabled'] -User $User
            Set-Statistics -Statistics $Statistics['Enabled'][$User.Level0] -User $User
        }
    }


    @{
        Summary    = $Summary
        Statistics = $Statistics
        Objects    = $Users
    }
}