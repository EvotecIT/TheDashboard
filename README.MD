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


### Install and configure IIS

TheDashboard can be used on any type of server as it generates static files that can be served by any web server. However, IIS is the most common one and it's the one I'm going to use in this example. IIS is also the one that I'm most familiar with.

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