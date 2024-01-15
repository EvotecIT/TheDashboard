Clear-Host
Import-Module .\TheDashboard.psd1 -Force

# This is configuration that should be used for SharePoint
# Please notice HTMLPath which has ASPX extension, as this is the only one supported by SharePoint
# Please notice UrlPath which is absolute path to SharePoint site. This is required if you want to use SharePoint with ASPX file as HomePage
Start-TheDashboard -HTMLPath "$PSScriptRoot\Reports\Index.aspx" -UrlPath "https://evotecpoland.sharepoint.com/sites/TheDashboard/SitePages" -Logo 'https://evotec.xyz/wp-content/uploads/2021/04/Logo-evotec-bb.png' -ShowHTML {
    $Today = Get-Date
    $Forest = Get-ADForest
    $AllUsers = $Forest.Domains | ForEach-Object { Get-ADUser -Filter * -Properties 'DistinguishedName' -Server $_ }
    $AllComputers = $Forest.Domains | ForEach-Object { Get-ADComputer -Filter * -Properties 'DistinguishedName' -Server $_ }
    $AllGroups = $Forest.Domains | ForEach-Object { Get-ADGroup -Filter * -Server $_ }
    $AllGroupPolicies = $Forest.Domains | ForEach-Object { Get-GPO -All -Domain $_ }

    New-DashboardGage -Label 'Users' -MinValue 0 -MaxValue 500 -Value $AllUsers.Count -Date $Today
    New-DashboardGage -Label 'Computers' -MinValue 0 -MaxValue 200 -Value $AllComputers.Count -Date $Today
    New-DashboardGage -Label 'Groups' -MinValue 0 -MaxValue 200 -Value $AllGroups.Count -Date $Today
    New-DashboardGage -Label 'Group Policies' -MinValue 0 -MaxValue 200 -Value $AllGroupPolicies.Count -Date $Today
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
} -StatisticsPath "$PSScriptRoot\Dashboard.xml" -Verbose -Online