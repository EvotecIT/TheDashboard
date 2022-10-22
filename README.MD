



### Install and configure IIS


#### Install IIS roles
Install all required roles (may be too much, but it works)

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

Enable windows authentication and disable anonymous authentication

```powershell
Write-Host Disable anonymous authentication
Set-WebConfigurationProperty -Filter '/system.webServer/security/authentication/anonymousAuthentication' -Name 'enabled' -Value 'false' -PSPath 'IIS:\Sites\Default Web Site'
Write-Host Enable windows authentication
Set-WebConfigurationProperty -Filter '/system.webServer/security/authentication/windowsAuthentication' -Name 'enabled' -Value 'true' -PSPath 'IIS:\Sites\Default Web Site'
```

#### Install certificate



#### Force Redirect to HTTPS

Install and configure IIS URL Rewrite module (from HTTP to HTTPS)

https://www.iis.net/downloads/microsoft/url-rewrite#additionalDownloads


####