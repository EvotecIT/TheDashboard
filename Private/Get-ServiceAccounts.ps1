function Get-ServiceAccount {
    [cmdletBinding()]
    param(
        [System.Collections.IDictionary] $Cache,
        [Array] $AllUsers
    )
    $Groups = 'WO_SVC Allow Interactive RDP login', 'WO_SVC Deny Interactive RDP login'
    $Today = Get-Date
    $GroupMembersCache = @{}
    $AllServices = foreach ($U in $AllUsers) {
        if (($U.SamAccountName -like '*svc*' -and $U.SamAccountName.length -gt 4) -or $U.Name -like "*svc*") {
            $U
        }
    }
    $Users = @(
        foreach ($Group in $Groups) {
            $GroupMembers = Get-WinADGroupMember -Identity $Group
            foreach ($User in $GroupMembers) {
                if ($User.Type -eq 'user') {
                    # Lets cache all users from groups
                    $GroupMembersCache[$User.DistinguishedName] = $Cache[$User.DistinguishedName]
                    # Lets find details about user
                    Get-PreparedUserInformation -User $Cache[$User.DistinguishedName] -Cache $Cache -Group $Group -Today $Today
                }
            }
        }
        $ServiceAccounts = Get-ADServiceAccount -Filter * -Properties mail, LastLogonDate, PasswordLastSet, DisplayName, ObjectClass
        foreach ($Service in $ServiceAccounts) {
            Get-PreparedUserInformation -User $Service -Cache $Cache -Today $Today
        }
        foreach ($Service in $AllServices) {
            if (-not $GroupMembersCache[$Service.DistinguishedName]) {
                Get-PreparedUserInformation -User $Service -Cache $Cache -Today $Today
            }
        }
    )
    $Users
}