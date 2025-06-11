### 0.0.40 - 2025.06.11
- Added ability to link logo or use home link

### 0.0.39 - 2025.03.17
- Fix issues around removing empty properties
- Added additional logging

### 0.0.38 - 2025.03.17
- Fix issues around removing empty properties

### 0.0.37 - 2025.03.17
- Added more logging

### 0.0.36 - 2025.03.05
- Improve dashboard logic for menu generation and added some docs around it

### 0.0.35 - 2025.02.21
- Add ability to force regeneration

### 0.0.34 - 2025.01.24
- Added ability to log things

### 0.0.33 - 2025.01.22
- Improves dashboard logic for excluding files

### 0.0.32 - 2025.01.22
- Improves dashboard logic for excluding files

### 0.0.31 - 2025.01.22
- Improves dashboard logic for excluding files

### 0.0.30 - 2025.01.06
- Added `PassThru` to get the output of `Start-TheDashboard` to be able to use it in other scripts
- Added ability to cleanup files not in use by the dashboard (it actually deletes the files, be sure you want to do it)
- Supports `WhatIf` for cleanup of files

### 0.0.29 - 2024.10.18
- Add `Title` to the pages for better page distinction

### 0.0.28 - 2024.05.01
- Improve `Repair-DashboardContent` to fix issues with PS 5.1

### 0.0.27 - 2024.05.01
- Improve `Repair-DashboardContent` to add ability to bump time by one minute
- Improve `New-DashboardReplacement` to allow for more complex replacements

### 0.0.25 - 2024.04.26
- Improvements overall
- Added `Repair-DashboardContent` to fix issues with HTML incompatible with SharePoint
- Added `Repair-DashboardExtension` to convert HTML files to ASPX files or vice versa (for SharePoint)
- New options to `New-DashboardReplacement` to allow for more complex replacements

### 0.0.22 - 2024.02.29
- Improvements overall

### 0.0.21 - 2023.11.17
- Fix for relative folders

### 0.0.20 - 2023.11.17
- Make links without spaces
- Fix links to reports

### 0.0.19 - 2023.11.16
- Fix for sorting of reports in menu (again)
- Remove not needed field

### 0.0.18 - 2023.11.16
- Respect extension on cleanup of old html files

### 0.0.17 - 2023.11.16
- Fix for sorting of reports in menu
- Fix for sorting descending when using limits

### 0.0.16 - 2023.10.16
- Fix for primary calendar showing history reports

### 0.0.15 - 2023.10.13
- Ignore XML files when generating reports

### 0.0.14 - 2023.10.05
- `New-DashboardLimit` now works on global level

### 0.0.13 - 2023.08.31
- Removed -Force from `Start-TheDashboard` as it was not really useful causing inconsistent reports
- Added `New-DashboardLimit` to limit number of reports generated and allow history reports
- Reworked few things making it easier to use and better overall

### 0.0.12 - 2023.03.29
- Fixes an issue with file being overwritten with pages with same name

### 0.0.11 - 2023.03.27
- Fixes a bug when using old configuration that would not regenerate all HTML files

### 0.0.10 - 2023.03.25
- Allow new way to define the dashboard using `New-Dashboard*` cmdlets

```powershell
Start-TheDashboard -HTMLPath "$PSScriptRoot\Reports\Index.html" -Logo 'https://evotec.xyz/wp-content/uploads/2021/04/Logo-evotec-bb.png' -ShowHTML {
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
    New-DashboardFolder -Name 'ADEssentials' -IconBrands gofore -UrlName 'ADEssentials' -Path $PSScriptRoot\Reports\ADEssentials {
        New-DashboardReplacement -SplitOn "_" -AddSpaceToName
        New-DashboardReplacement -BeforeSplit @{
            'GPOZaurr'         = ''
            'PingCastle-'      = ''
            'Testimo'          = ''
            'GroupMembership-' = ''
            '_Regional'        = ' Regional'
        }
        New-DashboardReplacement -AfterSplit @{
            'G P O'     = 'GPO'
            'L A P S'   = 'LAPS'
            'L D A P'   = 'LDAP'
            'K R B G T' = 'KRBGT'
            'I N S'     = 'INS'
            'I T R X X' = 'ITRXX'
            'A D'       = 'AD'
        }
    } -DisableGlobalReplacement
    New-DashboardFolder -Name 'GPOZaurr' -IconBrands gofore -UrlName 'GPOzaurr' -Path $PSScriptRoot\Reports\GPOZaurr

    New-DashboardReplacement -SplitOn "_" -AddSpaceToName
    New-DashboardReplacement -BeforeSplit @{ 'GPOZaurr' = '' }
    New-DashboardReplacement -BeforeSplit @{ 'GroupMembership-' = ''; '_Regional' = ' Regional' }
    New-DashboardReplacement -BeforeSplit @{
        'GPOZaurr'    = ''
        'PingCastle-' = ''
        'Testimo'     = ''
    }
    New-DashboardReplacement -AfterSplit @{ 'G P O' = 'GPO' }, @{  'L D A P' = 'LDAP' }
    New-DashboardReplacement -AfterSplit @{ 'L A P S' = 'LAPS' }, @{  'K R B G T' = 'KRBGT' }
    New-DashboardReplacement -AfterSplit @{ 'A D' = 'AD' }, @{  'I T R X X' = 'ITRXX' }, @{  'I N S' = 'INS' }
} -StatisticsPath "$PSScriptRoot\Dashboard.xml" -Verbose -Online -Force
```

- Better handling of naming when not doing replacements
- Rearranged some code to make it work nicer
- Added some more output

### 0.0.9 - 2022.12.19
- Fixes ordering of reports in menu - should be alphabetical from now on
- Improves performance of report generation by generating only new reports and not all reports
  - Using the `-Force` flag will generate all reports. Keep in mind it can take very long time to generate all reports in some environments