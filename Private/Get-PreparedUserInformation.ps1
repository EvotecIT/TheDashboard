function Get-PreparedUserInformation {
    [cmdletBinding()]
    param(
        [Object] $User,
        [System.Collections.IDictionary] $Cache,
        [string] $Group,
        [datetime] $Today,
        [switch] $ServiceAccounts
    )
    $UserLocation = ($User.DistinguishedName -split ',').Replace('OU=', '').Replace('CN=', '').Replace('DC=', '')
    #$Location = if ($UserLocation[-6] -eq $User.Name) { '' } else { $UserLocation[-6] }
    $Region = $UserLocation[-4]
    $Country = $UserLocation[-5]

    if ($User.LastLogonDate) {
        $LastLogonDays = $( - $($User.LastLogonDate - $Today).Days)
    } else {
        $LastLogonDays = $null
    }
    if ($User.PasswordLastSet) {
        $PasswordLastDays = $( - $($User.PasswordLastSet - $Today).Days)
    } else {
        $PasswordLastDays = $null
    }
    if ($User.Manager) {
        $Manager = $Cache[$User.Manager].DisplayName
        $ManagerSamAccountName = $Cache[$User.Manager].SamAccountName
        $ManagerEmail = $Cache[$User.Manager].Mail
        $ManagerEnabled = $Cache[$User.Manager].Enabled
        $ManagerLastLogon = $Cache[$User.Manager].LastLogonDate
        if ($ManagerLastLogon) {
            $ManagerLastLogonDays = $( - $($ManagerLastLogon - $Today).Days)
        } else {
            $ManagerLastLogonDays = $null
        }
        $ManagerStatus = if ($ManagerEnabled) { 'Enabled' } else { 'Disabled' }
    } else {
        if ($User.ObjectClass -eq 'user') {
            $ManagerStatus = 'Missing'
        } else {
            $ManagerStatus = 'Not available'
        }
        $Manager = $null
        $ManagerSamAccountName = $null
        $ManagerEmail = $null
        $ManagerEnabled = $null
        $ManagerLastLogon = $null
        $ManagerLastLogonDays = $null
    }

    if ($ServiceAccounts) {
        [PSCustomObject] @{
            Name                        = $User.Name
            SamAccountName              = $User.SamAccountName
            UserPrincipalName           = $User.UserPrincipalName
            Enabled                     = $User.Enabled
            ObjectClass                 = $User.ObjectClass
            IsMissing                   = if ($Group) { $false } else { $true }
            LastLogonDays               = $LastLogonDays
            PasswordLastDays            = $PasswordLastDays
            Manager                     = $Manager
            ManagerSamAccountName       = $ManagerSamAccountName
            ManagerEmail                = $ManagerEmail
            ManagerStatus               = $ManagerStatus
            ManagerLastLogonDays        = $ManagerLastLogonDays
            Level0                      = $Region
            Level1                      = $Country
            DistinguishedName           = $User.DistinguishedName
            LastLogonDate               = $User.LastLogonDate
            PasswordLastSet             = $User.PasswordLastSet
            PasswordNeverExpires        = $User.PasswordNeverExpires
            PasswordNotRequired         = $User.PasswordNotRequired
            PasswordExpired             = $User.PasswordExpired
            CannotChangePassword        = $User.CannotChangePassword
            AccountTrustedForDelegation = $User.AccountTrustedForDelegation
            ManagerDN                   = $User.Manager
            ManagerLastLogon            = $ManagerLastLogon
            Group                       = $Group
            Description                 = $User.Description
        }
    } else {
        [PSCustomObject] @{
            Name                        = $User.Name
            SamAccountName              = $User.SamAccountName
            UserPrincipalName           = $User.UserPrincipalName
            Enabled                     = $User.Enabled
            ObjectClass                 = $User.ObjectClass
            # The difference being this
            IsServiceAccount            = if ($Group) { $true } else { $false }
            LastLogonDays               = $LastLogonDays
            PasswordLastDays            = $PasswordLastDays
            Manager                     = $Manager
            ManagerSamAccountName       = $ManagerSamAccountName
            ManagerEmail                = $ManagerEmail
            ManagerStatus               = $ManagerStatus
            ManagerLastLogonDays        = $ManagerLastLogonDays
            Level0                      = $Region
            Level1                      = $Country
            DistinguishedName           = $User.DistinguishedName
            LastLogonDate               = $User.LastLogonDate
            PasswordLastSet             = $User.PasswordLastSet
            PasswordNeverExpires        = $User.PasswordNeverExpires
            PasswordNotRequired         = $User.PasswordNotRequired
            PasswordExpired             = $User.PasswordExpired
            CannotChangePassword        = $User.CannotChangePassword
            AccountTrustedForDelegation = $User.AccountTrustedForDelegation
            ManagerDN                   = $User.Manager
            ManagerLastLogon            = $ManagerLastLogon
            Group                       = $Group
            Description                 = $User.Description
        }
    }
}