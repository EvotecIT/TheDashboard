function Get-PreparedComputerInformation {
    [cmdletBinding()]
    param(
        $Computer,
        [System.Collections.IDictionary] $Cache,
        [string] $Group
    )
    $ComputerLocation = ($Computer.DistinguishedName -split ',').Replace('OU=', '').Replace('CN=', '').Replace('DC=', '')
    # $Location = if ($ComputerLocation[-6] -eq $Computer.Name) { '' } else { $ComputerLocation[-6] }
    $Region = $ComputerLocation[-4]
    $Country = $ComputerLocation[-5]

    if ($Computer.LastLogonDate) {
        $LastLogonDays = $( - $($Computer.LastLogonDate - $Today).Days)
    } else {
        $LastLogonDays = $null
    }
    if ($Computer.PasswordLastSet) {
        $PasswordLastDays = $( - $($Computer.PasswordLastSet - $Today).Days)
    } else {
        $PasswordLastDays = $null
    }
    <#
    if ($Computer.Manager) {
        $Manager = $Cache[$Computer.Manager].DisplayName
        $ManagerEmail = $Cache[$Computer.Manager].Mail
        $ManagerEnabled = $Cache[$Computer.Manager].Enabled
        $ManagerLastLogon = $Cache[$Computer.Manager].LastLogonDate
        if ($ManagerLastLogon) {
            $ManagerLastLogonDays = $( - $($ManagerLastLogon - $Today).Days)
        } else {
            $ManagerLastLogonDays = $null
        }
        $ManagerStatus = if ($ManagerEnabled) { 'Enabled' } else { 'Disabled' }
    } else {
        if ($Computer.ObjectClass -eq 'user') {
            $ManagerStatus = 'Missing'
        } else {
            $ManagerStatus = 'Not available'
        }
        $Manager = $null
        $ManagerEmail = $null
        $ManagerEnabled = $null
        $ManagerLastLogon = $null
        $ManagerLastLogonDays = $null
    }
    #>

    [PSCustomObject] @{
        Name                   = $Computer.Name
        SamAccountName         = $Computer.SamAccountName
        #UserPrincipalName    = $Computer.UserPrincipalName
        Enabled                = $Computer.Enabled
        LastLogonDays          = $LastLogonDays
        PasswordLastDays       = $PasswordLastDays
        #Manager              = $Manager
        #ManagerEmail         = $ManagerEmail
        #ManagerStatus        = $ManagerStatus
        #ManagerLastLogonDays = $ManagerLastLogonDays
        Level0                 = $Region
        Level1                 = $Country
        OperatingSystem        = $Computer.OperatingSystem
        OperatingSystemVersion = $Computer.OperatingSystemVersion
        DistinguishedName      = $Computer.DistinguishedName
        LastLogonDate          = $Computer.LastLogonDate
        PasswordLastSet        = $Computer.PasswordLastSet
        PasswordNeverExpires   = $Computer.PasswordNeverExpires
        PasswordNotRequired    = $Computer.PasswordNotRequired
        PasswordExpired        = $Computer.PasswordExpired
        ManagerDN              = $Computer.Manager
        #ManagerLastLogon     = $ManagerLastLogon
        #Group                = $Group
        Description            = $Computer.Description
        TrustedForDelegation   = $Computer.TrustedForDelegation
        #Location          = $Location
        #Region            = $Region
        #Country           = $Country
    }
}