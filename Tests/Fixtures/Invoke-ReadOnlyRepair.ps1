param(
    [string] $ModuleManifest,
    [string] $ReportRoot,
    [string] $SharedGoodsManifest,
    [string] $WriteHTMLManifest,
    [string] $WriteColorManifest
)

# Use an independent caller without an enclosing try/catch or Pester error handling.
$ErrorActionPreference = 'Stop'
Import-Module $SharedGoodsManifest -ErrorAction Stop
Import-Module $WriteHTMLManifest -ErrorAction Stop
Import-Module $WriteColorManifest -ErrorAction Stop
Import-Module $ModuleManifest -Force -ErrorAction Stop
$ErrorActionPreference = 'Continue'
Write-Output 'READY_TO_REPAIR'
Repair-DashboardContent -Directory $ReportRoot -ExtensionFrom '.html' -Search 'Original' -Replace 'Repaired' -PassThru
exit 0
