<p align="center">
  <a href="https://www.powershellgallery.com/packages/TheDashboard"><img src="https://img.shields.io/powershellgallery/v/TheDashboard.svg"></a>
  <a href="https://www.powershellgallery.com/packages/TheDashboard"><img src="https://img.shields.io/powershellgallery/v/TheDashboard.svg?label=powershell%20gallery%20preview&colorB=yellow&include_prereleases"></a>
  <a href="https://github.com/EvotecIT/TheDashboard"><img src="https://img.shields.io/github/license/EvotecIT/TheDashboard.svg"></a>
</p>

<p align="center">
  <a href="https://www.powershellgallery.com/packages/TheDashboard"><img src="https://img.shields.io/powershellgallery/p/TheDashboard.svg"></a>
  <a href="https://github.com/EvotecIT/TheDashboard"><img src="https://img.shields.io/github/languages/top/evotecit/TheDashboard.svg"></a>
  <a href="https://github.com/EvotecIT/TheDashboard"><img src="https://img.shields.io/github/languages/code-size/evotecit/TheDashboard.svg"></a>
  <a href="https://www.powershellgallery.com/packages/TheDashboard"><img src="https://img.shields.io/powershellgallery/dt/TheDashboard.svg"></a>
</p>

<p align="center">
  <a href="https://twitter.com/PrzemyslawKlys"><img src="https://img.shields.io/twitter/follow/PrzemyslawKlys.svg?label=Twitter%20%40PrzemyslawKlys&style=social"></a>
  <a href="https://evotec.xyz/hub"><img src="https://img.shields.io/badge/Blog-evotec.xyz-2A6496.svg"></a>
  <a href="https://www.linkedin.com/in/pklys"><img src="https://img.shields.io/badge/LinkedIn-pklys-0077B5.svg?logo=LinkedIn"></a>
</p>

# TheDashboard

*TheDashboard* is a PowerShell module that generates nice HTML dashboard that's main goal is to integrate multiple reports created by other PowerShell modules. It's main goal is to provide a single place to see all the information you need. It's not meant to be a replacement for other modules, but rather a way to integrate them into a single place.

A lot of modules that I've created over the years such as Tesimo, ADEssentials, GPOZaurr, or other external products such as PingCastle generate HTML output. While using those modules is great, it's not always easy to see all the information in one place. TheDashboard solves this problem.

### Features & ToDo

The main feature of TheDashboard is to generate HTML report that can be used to see all the information in one place.
While doing so, TheDashboard provides additional insights so that the picture of infrastructure is more complete.

- Gages with quick overview:
  - [x] Active Directory - Total number of computers
  - [x] Active Directory - Total number of users
  - [x] Active Directory - Total number of groups
  - [x] Active Directory - Total number of group policies

- Panels available for quick overview
  - [ ] Active Directory - Users changed password in last XXX days
  - [ ] Active Directory - Users with password never expires
  - [ ] Active Directory - Users with password expired in last XXX days
  - [ ] Active Directory - Users with password expiring in next XXX days
  - [ ] Active Directory - Computers with password last set over XXX days ago

### Report names and reliable generation

TheDashboard identifies a report by its original filename, before applying naming replacements. A trailing timestamp in the format `_yyyy-MM-dd_HHmmss` identifies a version of that report. For example, `PingCastle-Domain-example.test_2026-10-02_090000.html` and `PingCastle-Domain-group.example.test_2026-10-02_090000.html` create separate menu entries. Older timestamps for the same domain become versions of that entry. The timestamp determines report order; files without that suffix use their modification time.

Naming rules change display labels. They do not merge independent reports. Duplicate labels include the domain or original report name, and generated filename collisions receive a stable suffix. Standard PingCastle domain labels retain the complete domain, including hyphens. In `-PassThru` results, `MenuBuilder` entries within each section are keyed by the lowercase report identity. Named retention limits also recognize the label before disambiguation.

For `AfterSplitPositionName`, specific matches take precedence over the `*` fallback. Ordinary hashtables select the most specific pattern consistently. Use `[ordered]` when overlapping patterns need an explicit precedence; equally specific conflicting rules in an ordinary hashtable produce an error. Splitting on `_` preserves hyphens within domain names:

```powershell
$Root = Join-Path $PSScriptRoot 'Reports'
Start-TheDashboard -HTMLPath (Join-Path $Root 'Index.html') -StatisticsPath (Join-Path $PSScriptRoot 'Dashboard.xml') {
    New-DashboardFolder -Name 'PingCastle' -UrlName 'PingCastle' -Path (Join-Path $Root 'PingCastle')
    New-DashboardReplacement -BeforeSplit @{ 'PingCastle-' = '' } -SplitOn '_' -AddSpaceToName
    New-DashboardLimit -LimitItem 1 -IncludeHistory
}
```

Put report folders beneath the directory containing the landing page. Use `CopyFrom` or `MoveFrom` to collect external reports into those folders. `UrlName` is a filename prefix, so it must not contain path separators. The dashboard uses relative, escaped links and supports nested report folders. `-UrlPath` sets the base URL for navigation when hosting requires an absolute address.

Generated pages and statistics are staged before publishing. A publication exception rolls back files already replaced in that run. Concurrent generators targeting the same landing page are rejected. This protects against command failures; a static site host can still observe individual files changing during publication, and abrupt process termination is not a site-wide transaction.

The hidden `.<landing-page>.dashboard-manifest.clixml` file records which generated pages this dashboard owns. Cleanup removes obsolete owned pages and preserves other files. Keep this manifest beside the landing page between runs. On the first run after upgrading, existing pages have no ownership record and are preserved unless they are a planned output. Review obsolete legacy pages separately. Statistics are local generator state and do not need to be served by the web host.

Unchanged report pages are reused. Missing pages, changed report metadata, naming or navigation changes, logo changes, asset mode, and rendering template changes cause regeneration. `-Force` regenerates all pages. `CopyFrom` skips files with unchanged timestamps and sizes, and compares hashes when equal-size files have different timestamps. `MoveFrom` removes source files only after generation and publication succeed. `-RemoveNotIncluded` explicitly deletes raw reports excluded by retention; without `-IncludeHistory`, older excluded reports are also omitted from the upload list returned by `-PassThru`. When sections share a report directory, a raw report is retained if any section includes it.

Use `-TestMode -PassThru` or `-WhatIf -PassThru` to inspect the menu and planned output without writing dashboard pages, statistics, manifests, copied reports, or logs. Configuration script blocks still execute under `WhatIfPreference`; custom collectors must respect that preference if they perform writes. Collector errors and unreadable report folders stop generation before page publication and cleanup. Email and notification configuration is unsupported by `Start-TheDashboard` and produces an explicit error.

Normal generation runs without checking GitHub. Use `-CheckForUpdates` to request a version check. Omit `-Online` to embed the renderer's assets in the generated pages; use `-Online` when the host and viewers can reach its CDN resources. Upload included entries from `FilesToKeepOrRemove`, preserving the paths relative to the landing page directory. Deploy the generated pages together with their included raw reports. Add supporting file types with `New-DashboardFolder -Extension '.css', '.js', '.png'`; these files, including those in subdirectories, are included as assets in the upload list and do not create menu entries.

### Validate generation

The regression suite exercises naming, domain separation, retained history, preview mode, missing-page recovery, configuration changes, ownership cleanup, and publication failure. It uses the module's existing PSSharedGoods and PSWriteHTML dependencies and Pester 5.7.1 or later in the 5.x series.

```powershell
pwsh -NoProfile -File ./Tests/Invoke-GenerationTests.ps1
powershell -NoProfile -File ./Tests/Invoke-GenerationTests.ps1
```

The CI workflow runs the same suite on Windows PowerShell 5.1 and PowerShell 7 with public dependency versions.

### Examples

#### Example 1

Following example shows how to generate a dashboard

```powershell
Start-TheDashboard -HTMLPath "$PSScriptRoot\Reports\Index.html" -Logo 'https://evotec.xyz/wp-content/uploads/2021/04/Logo-evotec-bb.png' -ShowHTML {
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
    New-DashboardFolder -Name 'GroupPolicies' -IconBrands android -UrlName 'GPO' -Path $PSScriptRoot\Reports\GroupPolicies
    New-DashboardFolder -Name 'DomainControllers' -IconBrands android -UrlName 'DomainControllers' -Path $PSScriptRoot\Reports\DomainControllers

    # Global Replacements
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
        'D H C P'   = 'DHCP'
        'D F S'     = 'DFS'
        'D C'       = 'DC'
    }
    New-DashboardLimit -LimitItem 1 -IncludeHistory
} -StatisticsPath "$PSScriptRoot\Dashboard.xml" -Verbose -Online
```

![Image](/Data/TheDashboard2.png)

#### Example 2

Following example shows how to generate a dashboard

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

Generated HTML Dashboard

![Image](/Data/TheDashboard1.png)



### Hosting TheDashboard on IIS

TheDashboard can be used on any type of server as it generates static files that can be served by any web server.
It can run on IIS, Apache, Nginx, or any other web server.
However, IIS is the most common one and it's the one I'm going to use in this example.
IIS is also the one that I'm most familiar with.

#### Install IIS roles
Install all required roles (may be too much, but it works). If you think some roles are not needed, feel free to remove them (open PR/Issue).

```powershell
$Roles = @(
    'Web-Server'
    'Web-WebServer'
    'Web-Common-Http'
    'Web-Default-Doc'
    'Web-Dir-Browsing'
    'Web-Http-Errors'
    'Web-Static-Content'
    'Web-Http-Redirect'
    'Web-DAV-Publishing'
    'Web-Health'
    'Web-Http-Logging'
    'Web-Performance'
    'Web-Stat-Compression'
    'Web-Security'
    'Web-Filtering'
    'Web-IP-Security'
    'Web-Url-Auth'
    'Web-Windows-Auth'
    'Web-App-Dev'
    'Web-Net-Ext45'
    'Web-Asp-Net45'
    'Web-CGI'
    'Web-ISAPI-Ext'
    'Web-ISAPI-Filter'
    'Web-WebSockets'
    'Web-Mgmt-Tools'
    'Web-Mgmt-Console'
)

Install-WindowsFeature -Name $Roles
```

#### Enable Authentication
Once IIS is installed we need to make sure data is a little bit protected. Enable windows authentication and disable anonymous authentication

```powershell
Write-Host Disable anonymous authentication
Set-WebConfigurationProperty -Filter '/system.webServer/security/authentication/anonymousAuthentication' -Name 'enabled' -Value 'false' -PSPath 'IIS:\Sites\Default Web Site'
Write-Host Enable windows authentication
Set-WebConfigurationProperty -Filter '/system.webServer/security/authentication/windowsAuthentication' -Name 'enabled' -Value 'true' -PSPath 'IIS:\Sites\Default Web Site'
```

#### Install certificate


#### Force Redirect to HTTPS
By default HTTP is enabled and it's not a good idea to have it enabled. We need to force redirect to HTTPS. To do that we need to install URL Rewrite module and configure it.

You can download URL Rewrite from https://www.iis.net/downloads/microsoft/url-rewrite#additionalDownloads


### Hosting TheDashboard on SharePoint Online

TheDashboard can be hosted on SharePoint Online. It's a little bit more tricky than hosting it on IIS, but it's doable.
First of all SharePoint doesn't hosts HTML files directly. It hosts ASPX files. So we need to convert all HTML files to ASPX files.
Secondly, SharePoint doesn't like "<%" in the content. It tries to interpret it as a server block.
This is a problem because some of the reports generated by PowerShell modules contain "<%" in the content.


### Dashboard Repair Commands

TheDashboard module provides three repair commands to help fix common issues with dashboard files:

| Command | Purpose | Common Use Case |
|---------|---------|-----------------|
| `Repair-DashboardExtension` | Convert file extensions | Converting .html to .aspx for SharePoint hosting |
| `Repair-DashboardContent` | Fix content compatibility issues | Remove SharePoint-incompatible characters like `<%` |
| `Repair-DashboardEncoding` | Fix encoding issues | Convert UTF-8 with BOM to UTF-8 without BOM for emoji support |

All commands support `-WhatIf` to preview changes before applying them.

#### 1. Repair-DashboardExtension - Convert file extensions

Use this command to convert between .html and .aspx files, which is essential for SharePoint hosting.

```powershell
# Convert HTML files to ASPX for SharePoint
Repair-DashboardExtension -Path "C:\Reports" -ExtensionFrom ".html" -ExtensionTo ".aspx"

# Convert back from ASPX to HTML if needed
Repair-DashboardExtension -Path "C:\Reports" -ExtensionFrom ".aspx" -ExtensionTo ".html"

# Preview changes with WhatIf
Repair-DashboardExtension -Path "C:\Reports" -ExtensionFrom ".html" -ExtensionTo ".aspx" -WhatIf
```

#### 2. Repair-DashboardContent - Fix SharePoint compatibility issues

This is a fix for a SharePoint error that occurs when APSX file contains "<%"

> Sorry, something went wrong. An error occurred during the processing of /sites/TheDashboard/Shared Documents/Gpozaurr_GPOBrokenPartially_2024-03-27_025637.aspx. The server block is not well formed.

The reports created by several scripts (GPOZaurr/ADEssentials/Testimo) contain "<%" in the content, which causes SharePoint to try and interpret it as a server block.
In modules created by Evotec this is used by the Enlighter.JS library and may be added to file content if not used with CDN resources (lack of `Online` switch).
Since the enlighter.js library is put inside HTML directly it causes issues with SharePoint which tries to interpret it as a server block.
The script will replace "<%" with "<-%" in all files with the .aspx extension in the Reports folder.
Since we don't really use Enlighter.JS capability that uses this regex it should not cause issues

Use the built-in Repair-DashboardContent command:

```powershell
# Fix SharePoint "<%" server block errors
$SearchString = "_|:|@|#|<-|←|<:|<%|=|=>|⇒|>:"
$ReplaceString = "_|:|@|#|<-|←|<:|<-%|=|=>|⇒|>:"
Repair-DashboardContent -Directory "C:\Reports" -Search $SearchString -Replace $ReplaceString -EscapeRegex

# Remove Content-Security-Policy meta tags from PingCastle reports
$SearchString = '<meta http-equiv="Content-Security-Policy".*?/>'
$ReplaceString = ''
Repair-DashboardContent -Directory "C:\Reports" -Search $SearchString -Replace $ReplaceString

# Process only newer files (last 7 days) and add one minute to modification time
Repair-DashboardContent -Directory "C:\Reports" -Search $SearchString -Replace $ReplaceString -OnlyNewerThan 7 -AddOneMinute

# Preview changes with WhatIf
Repair-DashboardContent -Directory "C:\Reports" -Search "<%" -Replace "<-%" -WhatIf
```

#### 3. Repair-DashboardEncoding - Fix encoding issues (UTF-8 BOM causing emoji display problems)

If you're experiencing issues with emojis or special characters not displaying correctly in your dashboard, it's likely due to encoding issues. UTF-8 with BOM can cause problems in web environments. Use the new `Repair-DashboardEncoding` function to fix these issues:

```powershell
# Preview what encoding changes would be made
Repair-DashboardEncoding -Path "C:\Reports" -WhatIf

# Fix encoding issues for all HTML/ASPX files (converts UTF-8 with BOM to UTF-8 without BOM)
Repair-DashboardEncoding -Path "C:\Reports" -CreateBackups

# Fix encoding for specific file types
Repair-DashboardEncoding -Path "C:\Reports" -Extensions @('.html', '.aspx') -TargetEncoding UTF8

# Get detailed results of the repair process
$results = Repair-DashboardEncoding -Path "C:\Reports" -PassThru
$results | Where-Object { $_.HasEmojis -eq $true } | Format-Table FilePath, OriginalEncoding, NewEncoding, Status
```

This function will:
- Detect files with UTF-8 BOM encoding
- Convert them to UTF-8 without BOM (better for web compatibility)
- Identify files containing emojis
- Create backups if requested
- Provide detailed reporting of changes made
