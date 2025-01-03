Clear-Host
Import-Module .\TheDashboard.psd1 -Force

$Dashboard = Start-TheDashboard -HTMLPath "$PSScriptRoot\Reports\Index.html" -Logo 'https://evotec.xyz/wp-content/uploads/2021/04/Logo-evotec-bb.png' {
    # Gather data for gages
    $Today = Get-Date
    $Forest = Get-ADForest
    $AllUsers = $Forest.Domains | ForEach-Object { Get-ADUser -Filter * -Properties 'DistinguishedName' -Server $_ }
    $AllComputers = $Forest.Domains | ForEach-Object { Get-ADComputer -Filter * -Properties 'DistinguishedName' -Server $_ }
    $AllGroups = $Forest.Domains | ForEach-Object { Get-ADGroup -Filter * -Server $_ }
    $AllGroupPolicies = $Forest.Domains | ForEach-Object { Get-GPO -All -Domain $_ }

    # Top level gages
    New-DashboardGage -Label 'Users' -MinValue 0 -MaxValue 500 -Value $AllUsers.Count -Date $Today
    New-DashboardGage -Label 'Computers' -MinValue 0 -MaxValue 200 -Value $AllComputers.Count -Date $Today
    New-DashboardGage -Label 'Groups' -MinValue 0 -MaxValue 200 -Value $AllGroups.Count -Date $Today
    New-DashboardGage -Label 'Group Policies' -MinValue 0 -MaxValue 200 -Value $AllGroupPolicies.Count -Date $Today

    # Folder definitions
    New-DashboardFolder -Name 'ActiveDirectory' -IconBrands gofore -UrlName 'ActiveDirectory' -Path $PSScriptRoot\Reports\ActiveDirectory
    #New-DashboardFolder -Name 'GroupPolicies' -IconBrands android -UrlName 'GPO' -Path $PSScriptRoot\Reports\GroupPolicies
    #New-DashboardFolder -Name 'DomainControllers' -IconBrands android -UrlName 'DomainControllers' -Path $PSScriptRoot\Reports\DomainControllers
    New-DashboardFolder -Name 'Security' -IconBrands android -UrlName 'Security' -Path $PSScriptRoot\Reports\Security

    # Global Replacements
    New-DashboardReplacement -SplitOn "_" -AddSpaceToName
    New-DashboardReplacement -BeforeSplit @{
        'GPOZaurr'         = ''
        #'PingCastle-'      = ''
        'Testimo'          = ''
        'GroupMembership-' = ''
        '_Regional'        = ' Regional'
    }
    New-DashboardReplacement -AfterSplit @{
        'G P O'             = 'GPO'
        'L A P S'           = 'LAPS'
        'L D A P'           = 'LDAP'
        'K R B G T'         = 'KRBGT'
        'I N S'             = 'INS'
        'I T R X X'         = 'ITRXX'
        'A D'               = 'AD'
        'D H C P'           = 'DHCP'
        'D F S'             = 'DFS'
        'D C'               = 'DC'
        '-ad .evotec .pl'   = '- ad.evotec.pl'
        '-ad .evotec .xyz'  = '- ad.evotec.xyz'
        '-test .evotec .pl' = '- test.evotec.pl'
    }
    New-DashboardLimit -LimitItem 1 -IncludeHistoryLimit 2
} -StatisticsPath "$PSScriptRoot\Dashboard.xml" -Verbose -Online -ShowHTML -PassThru

$Dashboard.Files | Format-Table -AutoSize Name, Href, Menu, Date, Include, FullPath