Clear-Host
Import-Module .\TheDashboard.psd1 -Force

# this is an old way of setting up dashboard using hashtable
# it works, but has it's limits and doesn't provide you auto-completion for any parameters

$Configuration = @{
    HTMLPath       = "$PSScriptRoot\Reports\Index.html"
    StatisticsPath = "$PSScriptRoot\Dashboard.xml"
    Logo           = 'https://evotec.xyz/wp-content/uploads/2021/04/Logo-evotec-bb.png'
    Folders        = [ordered] @{
        ADEssentials       = @{
            Path               = "$PSScriptRoot\Reports\ADEssentials"
            Url                = "ADEssentials"
            IconType           = 'IconBrands'
            Icon               = 'gofore'
            ReplacementsGlobal = $true
            #CopyFrom           = ""
            #MoveFrom           = "C:\Support\GitHub\TheDashboard\Ignore\Reports\CustomReports"
        }
        GPOZaurr           = @{
            Path               = "$PSScriptRoot\Reports\GPOZaurr"
            Url                = "GPOzaurr"
            IconType           = 'IconBrands'
            Icon               = 'gofore'
            ReplacementsGlobal = $true
            #CopyFrom           = ""
            #MoveFrom           = "C:\Support\GitHub\TheDashboard\Ignore\Reports\CustomReports"
        }
        Testimo            = @{
            Path               = "$PSScriptRoot\Reports\Testimo"
            Url                = "Testimo"
            IconType           = 'IconBrands'
            Icon               = 'adversal'
            ReplacementsGlobal = $true
        }
        'Group Membership' = @{
            Path               = "$PSScriptRoot\Reports\GroupMembership"
            Url                = "GroupMembership"
            IconType           = 'IconSolid'
            Icon               = 'chalkboard-teacher'
            ReplacementsGlobal = $true
        }
        'Custom Reports'   = @{
            Path               = "$PSScriptRoot\Reports\CustomReports"
            Url                = "CustomReports"
            IconType           = 'IconSolid'
            Icon               = 'chalkboard-teacher'
            ReplacementsGlobal = $true
        }
        'PingCastle'       = @{
            Path               = "$PSScriptRoot\Reports\PingCastle"
            Url                = "PingCastle"
            IconType           = 'IconSolid'
            Icon               = 'podcast'
            ReplacementsGlobal = $false
            Replacements       = [ordered] @{
                SplitOn        = '_'
                BeforeSplit    = [ordered] @{
                    '-Domain-' = ' '
                }
                AfterSplit     = [ordered] @{

                }
                AddSpaceToName = $false
            }
        }
    }
    Replacements   = [ordered] @{
        SplitOn        = '_'
        BeforeSplit    = [ordered] @{
            'Testimo'          = ''
            'GPOZaurr'         = ''
            'GroupMembership-' = ''
            '_Regional'        = ' Regional'
            'PingCastle-'      = ''
        }
        AfterSplit     = [ordered] @{
            'G P O'     = 'GPO'
            'L D A P'   = 'LDAP'
            'L A P S'   = 'LAPS'
            'K R B G T' = 'KRBGT'
            'A D'       = 'AD'
            'I T R X X' = 'ITRXX'
            'I N S'     = 'INS'
        }
        AddSpaceToName = $true
    }
}

Start-TheDashboard @Configuration -ShowHTML {
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
} -Verbose -Online -Force