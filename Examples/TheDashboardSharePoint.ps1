Clear-Host
Import-Module .\TheDashboard.psd1 -Force

# This is configuration that should be used for SharePoint
# Please notice HTMLPath which has ASPX extension, as this is the only one supported by SharePoint
# Please notice UrlPath which is absolute path to SharePoint site. This is required if you want to use SharePoint with ASPX file as HomePage
$Data = Start-TheDashboard -HTMLPath "$PSScriptRoot\Reports\Index.aspx" -UrlPath "https://evotecpoland.sharepoint.com/sites/TheDashboardTest/SitePages" -Logo 'https://evotec.xyz/wp-content/uploads/2021/04/Logo-evotec-bb.png' -ShowHTML:$false {
    $Today = Get-Date
    $Forest = Get-ADForest
    # $AllUsersCount = $Forest.Domains | ForEach-Object { (Get-ADObject -LDAPFilter "(objectClass=user)" -Server $_).Count }
    # $AllComputersCount = $Forest.Domains | ForEach-Object { (Get-ADObject -LDAPFilter "(objectClass=computer)" -Server $_).Count }
    # $AllGroupsCount = $Forest.Domains | ForEach-Object { (Get-ADObject -LDAPFilter "(objectClass=group)" -Server $_).Count }
    # $AllGroupPoliciesCount = $Forest.Domains | ForEach-Object { (Get-ADObject -LDAPFilter "(objectClass=groupPolicyContainer)" -Server $_).Count }


    $AllUsersCount = $Forest.Domains | ForEach-Object { (Get-ADObject -LDAPFilter "(objectClass=user)" -Server $_).Count } | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    $AllComputersCount = $Forest.Domains | ForEach-Object { (Get-ADObject -LDAPFilter "(objectClass=computer)" -Server $_).Count } | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    $AllGroupsCount = $Forest.Domains | ForEach-Object { (Get-ADObject -LDAPFilter "(objectClass=group)" -Server $_).Count } | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    $AllGroupPoliciesCount = $Forest.Domains | ForEach-Object { (Get-ADObject -LDAPFilter "(objectClass=groupPolicyContainer)" -Server $_).Count } | Measure-Object -Sum | Select-Object -ExpandProperty Sum

    New-DashboardGage -Label 'Users' -MinValue 0 -MaxValue 500 -Value $AllUsersCount -Date $Today
    New-DashboardGage -Label 'Computers' -MinValue 0 -MaxValue 200 -Value $AllComputersCount -Date $Today
    New-DashboardGage -Label 'Groups' -MinValue 0 -MaxValue 200 -Value $AllGroupsCount -Date $Today
    New-DashboardGage -Label 'Group Policies' -MinValue 0 -MaxValue 200 -Value $AllGroupPoliciesCount -Date $Today
    # New-DashboardFolder -Name 'Active Directory' -IconBrands gofore -UrlName 'ActiveDirectory' -Path $PSScriptRoot\Reports\ActiveDirectory {
    #     New-DashboardReplacement -SplitOn "[_-]" -AddSpaceToName
    #     New-DashboardReplacement -BeforeSplit @{
    #         'GPOZaurr'         = ''
    #         'PingCastle-'      = ''
    #         'Testimo'          = ''
    #         'GroupMembership-' = ''
    #         '_Regional'        = ' Regional'
    #     }
    #     New-DashboardReplacement -AfterSplit @{
    #         'G P O'     = 'GPO'
    #         'L A P S'   = 'LAPS'
    #         'L D A P'   = 'LDAP'
    #         'K R B G T' = 'KRBGT'
    #         'I N S'     = 'INS'
    #         'I T R X X' = 'ITRXX'
    #         'A D'       = 'AD'
    #         'D H C P'   = 'DHCP'
    #     }
    #
    #     #New-DashboardLimit -Name 'GPO Blocked Inheritance' -LimitItem 1
    #     #New-DashboardLimit -Name 'Password Quality 1' -LimitItem 1
    # } -DisableGlobalReplacement
    New-DashboardFolder -Name 'Group Policies' -IconBrands android -UrlName 'GPO' -Path $PSScriptRoot\Reports\TestPolicies
    New-DashboardFolder -Name 'Windows Updates' -IconBrands android -UrlName 'WindowsUpdates' -Path $PSScriptRoot\Reports\WindowsUpdates {
        $newDashboardReplacementSplat = @{
            BeforeSplit             = @{
                'GroupMembership-' = ''
                '_Regional'        = ' Regional'
                'GPOZaurr'         = ''
                'Testimo'          = ''
            }
            #AfterSplitPositionName  = 1, 2
            AfterSplitPositionName  = [ordered] @{
                'PingCastle-Domain-*' = 0, 2
                '*'                   = 0
                # '*'              = 1, 2
            }
            AfterRemoveDoubleSpaces = $true
            AfterUpperChars         = "evotec.com", "test.com"
            AfterSplit              = @{
                'G P O'     = 'GPO'
                'L D A P'   = 'LDAP'
                'D H C P'   = 'DHCP'
                'A D'       = 'AD'
                'I T R X X' = 'ITRXX'
                'I N S'     = 'INS'
                'L A P S'   = 'LAPS'
                'K R B G T' = 'KRBGT'
            }
            SplitOn                 = "[_-]"
            AddSpaceToName          = $true
        }
        New-DashboardReplacement @newDashboardReplacementSplat
        New-DashboardLimit -LimitItem 2 -IncludeHistory
    } -DisableGlobalReplacement

    #New-DashboardFolder -Name 'Test' -IconBrands android -UrlName 'New1' -Path $PSScriptRoot\Reports\New1
    New-DashboardReplacement -SplitOn "[_-]" -AddSpaceToName
    New-DashboardReplacement -BeforeSplit @{ 'GPOZaurr' = '' }
    New-DashboardReplacement -BeforeSplit @{ 'GroupMembership-' = ''; '_Regional' = ' Regional' }
    New-DashboardReplacement -BeforeSplit @{
        'GPOZaurr'    = ''
        'PingCastle-' = ''
        'Testimo'     = ''
    }
    New-DashboardLimit -LimitItem 2 -IncludeHistory
    New-DashboardReplacement -AfterSplit @{ 'G P O' = 'GPO' }, @{  'L D A P' = 'LDAP' }, @{ 'D H C P' = 'DHCP' }
    New-DashboardReplacement -AfterSplit @{ 'L A P S' = 'LAPS' }, @{  'K R B G T' = 'KRBGT' }
    New-DashboardReplacement -AfterSplit @{ 'A D' = 'AD' }, @{  'I T R X X' = 'ITRXX' }, @{  'I N S' = 'INS' }
} -StatisticsPath "$PSScriptRoot\Dashboard.xml" -Verbose -Online -Debug -PassThru