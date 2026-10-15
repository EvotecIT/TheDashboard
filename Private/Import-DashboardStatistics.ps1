function Import-DashboardStatistics {
    <#
    .SYNOPSIS
    Loads saved generation state and adds the current gauge samples.

    .DESCRIPTION
    Accepts current state dictionaries and the legacy statistics-only layout.
    Missing state starts empty; unreadable or invalid state is an error. Adds current
    gauge values in memory without writing the statistics file.

    .PARAMETER StatisticsPath
    Optional CLIXML state file to read.

    .PARAMETER GageConfiguration
    Gauge records containing Date, Label, and Value properties.

    .OUTPUTS
    A dictionary containing MenuBuilder and Statistics dictionaries.
    #>
    [CmdletBinding()]
    param(
        [string] $StatisticsPath,
        [Array] $GageConfiguration
    )
    $ExportData = [ordered] @{
        MenuBuilder = [ordered] @{}
        Statistics  = [ordered] @{}
    }
    if ($StatisticsPath -and (Test-Path -LiteralPath $StatisticsPath)) {
        Write-Color -Text '[i]', "[TheDashboard] ", 'Importing Statistics', ' [Informative] ', $StatisticsPath -Color Yellow, DarkGray, Yellow, DarkGray, Magenta
        $ImportedData = Import-Clixml -LiteralPath $StatisticsPath -ErrorAction Stop
        if ($ImportedData -isnot [System.Collections.IDictionary]) {
            throw 'The statistics file must contain a dictionary.'
        }
        if (-not $ImportedData.Contains('Statistics')) {
            $ExportData.Statistics = $ImportedData
        } else {
            $ExportData = $ImportedData
        }
    }
    foreach ($E in $GageConfiguration) {
        if (-not $ExportData['Statistics'].Contains($E.Date)) {
            $ExportData['Statistics'][$E.Date] = [ordered] @{}
        }
        $ExportData['Statistics'][$E.Date].Date = $E.Date
        $ExportData['Statistics'][$E.Date][$E.Label] = $E.Value
    }
    $ExportData
}
