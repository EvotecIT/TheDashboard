<#
.SYNOPSIS
Builds a dashboard with Active Directory account, group, and GPO counts.
.DESCRIPTION
Uses the ActiveDirectory and GroupPolicy modules to collect counts across the current forest.
.PARAMETER HTMLPath
Path to the dashboard landing page.
.PARAMETER ReportDirectory
Existing directory of HTML reports beneath the landing page directory.
.PARAMETER StatisticsPath
Optional path to the statistics file that stores gauge history.
.EXAMPLE
./Examples/TheDashboardActiveDirectoryGauges.ps1 -HTMLPath './Dashboard/Index.html' -ReportDirectory './Dashboard/Reports'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $HTMLPath,
    [Parameter(Mandatory)][string] $ReportDirectory,
    [string] $StatisticsPath
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../TheDashboard.psd1') -Force

$Date = Get-Date
$Domains = (Get-ADForest).Domains
$Users = @(foreach ($Domain in $Domains) { Get-ADUser -Server $Domain -Filter * -Properties Enabled })
$Computers = @(foreach ($Domain in $Domains) { Get-ADComputer -Server $Domain -Filter * -Properties Enabled })
$Groups = @(foreach ($Domain in $Domains) { Get-ADGroup -Server $Domain -Filter * -Properties GroupCategory })
$GroupPolicies = @(foreach ($Domain in $Domains) { Get-GPO -Domain $Domain -All })

$UserMax = [Math]::Max(1, $Users.Count)
$ComputerMax = [Math]::Max(1, $Computers.Count)
$GroupMax = [Math]::Max(1, $Groups.Count)

Start-TheDashboard -HTMLPath $HTMLPath -StatisticsPath $StatisticsPath {
    New-DashboardGage -Label 'Enabled users' -MaxValue $UserMax -Value @($Users | Where-Object Enabled).Count -Date $Date
    New-DashboardGage -Label 'Disabled users' -MaxValue $UserMax -Value @($Users | Where-Object Enabled -EQ $false).Count -Date $Date
    New-DashboardGage -Label 'Enabled computers' -MaxValue $ComputerMax -Value @($Computers | Where-Object Enabled).Count -Date $Date
    New-DashboardGage -Label 'Disabled computers' -MaxValue $ComputerMax -Value @($Computers | Where-Object Enabled -EQ $false).Count -Date $Date
    New-DashboardGage -Label 'Security groups' -MaxValue $GroupMax -Value @($Groups | Where-Object GroupCategory -EQ 'Security').Count -Date $Date
    New-DashboardGage -Label 'Distribution groups' -MaxValue $GroupMax -Value @($Groups | Where-Object GroupCategory -EQ 'Distribution').Count -Date $Date
    New-DashboardGage -Label 'Group Policies' -MaxValue ([Math]::Max(200, $GroupPolicies.Count)) -Value $GroupPolicies.Count -Date $Date

    New-DashboardFolder -Name 'Active Directory' -UrlName 'AD' -Path $ReportDirectory
}
