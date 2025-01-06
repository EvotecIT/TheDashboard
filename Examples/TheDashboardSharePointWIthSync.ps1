Clear-Host
Import-Module C:\Support\GitHub\SharePointEssentials\SharePointEssentials.psd1 -Force
Import-Module .\TheDashboard.psd1 -Force

# This is configuration that should be used for SharePoint
# Please notice HTMLPath which has ASPX extension, as this is the only one supported by SharePoint
# Please notice UrlPath which is absolute path to SharePoint site. This is required if you want to use SharePoint with ASPX file as HomePage
$Dashboard = Start-TheDashboard -HTMLPath "$PSScriptRoot\Reports\Index.aspx" -UrlPath "https://evotecpoland.sharepoint.com/sites/TheDashboardTest/SitePages" -Logo 'https://evotec.xyz/wp-content/uploads/2021/04/Logo-evotec-bb.png' -ShowHTML:$false {
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
    New-DashboardFolder -Name 'ActiveDirectory' -IconBrands gofore -UrlName 'ActiveDirectory' -Path $PSScriptRoot\Reports\ActiveDirectory
    New-DashboardFolder -Name 'Group Policies' -IconBrands android -UrlName 'GPO' -Path $PSScriptRoot\Reports\TestPolicies
    New-DashboardFolder -Name 'Windows Updates' -IconBrands android -UrlName 'WindowsUpdates' -Path $PSScriptRoot\Reports\WindowsUpdates {
        $newDashboardReplacementSplat = @{
            BeforeSplit             = @{
                'GroupMembership-' = ''
                '_Regional'        = ' Regional'
                'GPOZaurr'         = ''
                'PingCastle-'      = ''
                'Testimo'          = ''
            }
            #AfterSplitPositionName  = 1, 2
            AfterSplitPositionName  = [ordered] @{
                'WindowsUpdates*' = 1, 2
                '*'               = 1
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
} -StatisticsPath "$PSScriptRoot\Dashboard.xml" -Verbose -Online -PassThru

# We're using Sync-FilesToSharePoint to sync files to SharePoint
# This is a simple way to keep files in sync with SharePoint
# Since we want to make sure we only sync files that are included in the dashboard, and not everything in the folder
# We're using $Dashboard.FilesToKeepOrRemove to get the list of files that are included in the dashboard
# And provide it to Sync-FilesToSharePoint usig SourceFileList parameter
# If you want to sync all files, you can use SourceFolderPath parameter instead
$SharePointNeededFiles = ($Dashboard.FilesToKeepOrRemove | Where-Object { $_.Status -eq 'Included' }).Path

$Url = 'https://evotecpoland.sharepoint.com/sites/TheDashboardTest'
$ClientID = '438511c4-75de-4bc5-90ba-c58bd278396e' # Temp SharePoint App
$TenantID = 'ceb371f6-8745-4876-a040-69f2d10a9d1a'
$Thumbprint = '2CD8A0409F7A3E0E5902D939F6CDF6080D759E3C'

Connect-PnPOnline -Url $Url -ClientId $ClientID -Thumbprint $Thumbprint -Tenant $TenantID

$syncFileShareToSPOSplat = @{
    SiteUrl           = 'https://evotecpoland.sharepoint.com/sites/TheDashboardTest'
    #SourceFolderPath  = "C:\Support\GitHub\TheDashboard\Examples\Reports"
    SourceFileList    = $SharePointNeededFiles
    TargetLibraryName = "SitePages"
    LogPath           = "$PSScriptRoot\Logs\Sync-FilesToSharePoint-$($(Get-Date).ToString('yyyy-MM-dd_HH_mm_ss')).log"
    LogMaximum        = 5
    Include           = "*.aspx"
}

Sync-FilesToSharePoint @syncFileShareToSPOSplat