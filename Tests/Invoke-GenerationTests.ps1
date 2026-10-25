<#
.SYNOPSIS
Runs the generation regression suite against the source module.

.PARAMETER SharedGoodsManifest
Optional explicit PSSharedGoods manifest used for dependency qualification.

.PARAMETER WriteHTMLManifest
Optional explicit PSWriteHTML manifest used for dependency qualification.

.PARAMETER ResultPath
Optional Pester XML result destination. Exits with code one if tests fail or none pass.
#>
[CmdletBinding()]
param(
    [string] $SharedGoodsManifest,
    [string] $WriteHTMLManifest,
    [string] $ResultPath
)
$ErrorActionPreference = 'Stop'
if ($SharedGoodsManifest) {
    Import-Module $SharedGoodsManifest -ErrorAction Stop
}
if ($WriteHTMLManifest) {
    Import-Module $WriteHTMLManifest -ErrorAction Stop
}
# Source tests need the logging helper that the package builder normally merges into the module.
Import-Module PSWriteColor -RequiredVersion 1.0.3 -ErrorAction Stop
Import-Module Pester -MinimumVersion 5.7.1 -MaximumVersion 5.99.0 -ErrorAction Stop
$Configuration = New-PesterConfiguration
$Configuration.Run.Path = $PSScriptRoot
$Configuration.Run.PassThru = $true
$Configuration.Output.Verbosity = 'Normal'
if ($ResultPath) {
    $Configuration.TestResult.Enabled = $true
    $Configuration.TestResult.OutputPath = $ResultPath
}
$Result = Invoke-Pester -Configuration $Configuration
if ($Result.FailedCount -gt 0 -or $Result.PassedCount -eq 0) {
    exit 1
}
