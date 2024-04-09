<p align="center">
  <a href="https://www.powershellgallery.com/packages/TheDashboard"><img src="https://img.shields.io/powershellgallery/v/TheDashboard.svg"></a>
  <a href="https://www.powershellgallery.com/packages/TheDashboard"><img src="https://img.shields.io/powershellgallery/vpre/TheDashboard.svg?label=powershell%20gallery%20preview&colorB=yellow"></a>
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


### Help commands

#### Convert all .html files to .aspx files or vice versa

```powershell
$ExtensionFrom = '.html'
$ExtensionTo = '.aspx'

#$ExtensionFrom = '.aspx'
#$ExtensionTo = '.html'

$Files = Get-ChildItem -Path $PSScriptRoot\Reports -File -Recurse -Include "*$ExtensionFrom"
foreach ($File in $Files) {
    if ($File.Extension -eq $ExtensionFrom) {
        # Rename extension to .aspx
        $NewName = $File.FullName -replace "$($ExtensionFrom)$", $ExtensionTo
        Rename-Item -Path $File.FullName -NewName $NewName -Force
    }
}
```

#### Fix potential SharePoint online error

This is a fix for a SharePoint error that occurs when APSX file contains "<%"

> Sorry, something went wrong. An error occurred during the processing of /sites/TheDashboard/Shared Documents/Gpozaurr_GPOBrokenPartially_2024-03-27_025637.aspx. The server block is not well formed.

The reports created by several scripts (GPOZaurr/ADEssentials/Testimo) contain "<%" in the content, which causes SharePoint to try and interpret it as a server block.
In modules created by Evotec this is used by the Enlighter.JS library and may be added to file content if not used with CDN resources (lack of `Online` switch).
Since the enlighter.js library is put inside HTML directly it causes issues with SharePoint which tries to interpret it as a server block.
The script will replace "<%" with "<-%" in all files with the .aspx extension in the Reports folder.
Since we don't really use Enlighter.JS capability that uses this regex it should not cause issues

First get this module from PowerShell Gallery as it gets `Get-FileEncoding` function that's needed for this script

```powershell
Install-Module PSSharedGoods -Force -Verbose
```

Then run the script. It will replace "<%" with "<-%" in all files with the .aspx extension in the Reports folder.

```powershell
# look for <%, if it's part of this string
$SearchString = [regex]::Escape("_|:|@|#|<-|←|<:|<%|=|=>|⇒|>:")

# lets replace it with "<-%", while it won't work, it will fix SharePoint error
$ReplaceString = [regex]::Escape("_|:|@|#|<-|←|<:|<-%|=|=>|⇒|>:")

$Directory = "C:\Users\przemyslaw.klys\Downloads"
$ExtensionFrom = '.aspx'
$Files = Get-ChildItem -Path $Directory -File -Recurse -Include "*$ExtensionFrom"
foreach ($File in $Files) {
    if ($File.Extension -eq $ExtensionFrom) {
        $Encoding = Get-FileEncoding -Path $File.FullName
        # Replace "<%" with "<-%"
        $FileContent = Get-Content -Raw -Path $File.FullName -Encoding $Encoding
        if ($FileContent -match $SearchString) {
            Write-Color -Text "Replacing offensive characters in $($File.FullName)" -Color Green
            $FileContent -replace $SearchString, $ReplaceString | Set-Content -Path $File.FullName -Encoding $Encoding  #-WhatIf
        }
    }
}
```