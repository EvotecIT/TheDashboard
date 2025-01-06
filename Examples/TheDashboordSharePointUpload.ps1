Import-Module C:\Support\GitHub\SharePointEssentials\SharePointEssentials.psd1 -Force

$Url = 'https://evotecpoland.sharepoint.com/sites/TheDashboardTest'
$ClientID = '438511c4-75de-4bc5-90ba-c58bd278396e' # Temp SharePoint App
$TenantID = 'ceb371f6-8745-4876-a040-69f2d10a9d1a'

Connect-PnPOnline -Url $Url -ClientId $ClientID -Thumbprint '2CD8A0409F7A3E0E5902D939F6CDF6080D759E3C' -Tenant $TenantID

$syncFileShareToSPOSplat = @{
    SiteUrl           = 'https://evotecpoland.sharepoint.com/sites/TheDashboardTest'
    SourceFolderPath  = "C:\Support\GitHub\TheDashboard\Examples\Reports"
    TargetLibraryName = "SitePages"
    LogPath           = "$PSScriptRoot\Logs\Sync-FilesToSharePoint-$($(Get-Date).ToString('yyyy-MM-dd_HH_mm_ss')).log"
    LogMaximum        = 5
    Include           = "*.aspx"
}

Sync-FilesToSharePoint @syncFileShareToSPOSplat