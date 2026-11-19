<#
.SYNOPSIS
Checks which gauges a generated dashboard displays when changing cities.
.DESCRIPTION
Serve ReportDirectory at BaseUri with a local HTTP server before running this test.
Requires PSParseHTML and the selected browser.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $ReportDirectory,
    [Parameter(Mandatory)][uri] $BaseUri,
    [ValidateSet('Edge', 'Firefox')][string] $Browser = 'Edge'
)

$ErrorActionPreference = 'Stop'
if ($BaseUri.Scheme -ne 'http' -or $BaseUri.Host -ne '127.0.0.1') {
    throw 'BaseUri must point to the loopback HTTP server serving ReportDirectory.'
}
Import-Module PSWriteColor -RequiredVersion 1.0.3
Import-Module PSWriteHTML -RequiredVersion 1.41.0
Import-Module (Join-Path $PSScriptRoot '../../TheDashboard.psd1') -Force
Import-Module PSParseHTML -MinimumVersion 3.0.9

$Date = [datetime]'2025-04-11'
foreach ($Mode in 'overall', 'cities-only') {
    $Directory = Join-Path $ReportDirectory $Mode
    $Reports = Join-Path $Directory 'Reports'
    $null = New-Item -Path $Reports -ItemType Directory -Force
    [IO.File]::WriteAllText((Join-Path $Reports 'Source.html'), '<html><body>Sample report</body></html>')
    $null = Start-TheDashboard -HTMLPath (Join-Path $Directory 'Index.html') {
        New-DashboardFolder -Name Reports -UrlName Reports -Path $Reports
        if ($Mode -eq 'overall') {
            New-DashboardGage -Label Users -Date $Date -MaxValue 100 -Value 61
            New-DashboardGage -Label Computers -Date $Date -MaxValue 100 -Value 35
        }
        New-DashboardGage -Label Users -Date $Date -MaxValue 30 -Value 17 -City 'Brighton & Hove'
        New-DashboardGage -Label Computers -Date $Date -MaxValue 20 -Value 9 -City 'Brighton & Hove'
        New-DashboardGage -Label Users -Date $Date -MaxValue 80 -Value 44 -City Warsaw
        New-DashboardGage -Label Computers -Date $Date -MaxValue 60 -Value 26 -City Warsaw
    } 6>$null
}

function Assert-VisibleGages {
    param([string] $City, [string] $Expected)

    $CityJson = ConvertTo-Json -InputObject $City -Compress
    $ExpectedJson = ConvertTo-Json -InputObject $Expected -Compress
    $Condition = @"
() => {
    const selector = document.querySelector("#dashboard-gage-city");
    if (selector?.selectedOptions[0]?.textContent !== $CityJson) return false;
    const visible = [...document.querySelectorAll("[data-gage-scope]:not([hidden]) div[id^=Gage] > svg")];
    if (!visible.length || visible.some(svg => svg.getBoundingClientRect().width === 0)) return false;
    const gages = visible.map(svg => [...svg.querySelectorAll("text")].map(text => text.textContent.trim()).join(":"));
    return gages.join("|") === $ExpectedJson;
}
"@
    try {
        $null = $Session.Page.WaitForFunctionAsync($Condition).GetAwaiter().GetResult()
    } catch {
        throw "Expected '$City' to display [$Expected]. $($_.Exception.Message)"
    }
}

$Options = @{ Browser = 'Firefox'; Visible = $false; ViewportWidth = 1280; ViewportHeight = 900 }
if ($Browser -eq 'Edge') {
    $Options.Browser = 'Chromium'
    $Options.BrowserChannel = 'msedge'
}
$Session = Start-HtmlBrowserSession -Url ([uri]::new($BaseUri, 'overall/Index.html')).AbsoluteUri @Options
try {
    $Session.Page.SetDefaultTimeout(10000)
    $Selector = $Session.Page.Locator('select#dashboard-gage-city')
    $Brighton = '17:Users:0:30|9:Computers:0:20'
    $Warsaw = '44:Users:0:80|26:Computers:0:60'
    $All = '61:Users:0:100|35:Computers:0:100'

    Assert-VisibleGages -City All -Expected $All
    $null = $Selector.SelectOptionAsync('city-0').GetAwaiter().GetResult()
    Assert-VisibleGages -City 'Brighton & Hove' -Expected $Brighton
    $null = $Selector.PressAsync('End').GetAwaiter().GetResult()
    Assert-VisibleGages -City Warsaw -Expected $Warsaw
    $null = $Selector.PressAsync('Home').GetAwaiter().GetResult()
    Assert-VisibleGages -City All -Expected $All

    $null = $Session.Page.SetViewportSizeAsync(390, 844).GetAwaiter().GetResult()
    $null = $Session.Page.GotoAsync(([uri]::new($BaseUri, 'cities-only/Index.html')).AbsoluteUri).GetAwaiter().GetResult()
    Assert-VisibleGages -City All -Expected "$Brighton|$Warsaw"
    $null = $Selector.SelectOptionAsync('city-1').GetAwaiter().GetResult()
    Assert-VisibleGages -City Warsaw -Expected $Warsaw
    $null = $Selector.SelectOptionAsync('all').GetAwaiter().GetResult()
    Assert-VisibleGages -City All -Expected "$Brighton|$Warsaw"
    "PASS: $Browser showed the expected gauge values and scales for All and each selected city."
} finally {
    Close-HtmlBrowserSession -Session $Session -ErrorAction Stop
}
