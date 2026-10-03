function Import-DashboardStatistics {
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
        if ($ImportedData -isnot [System.Collections.IDictionary]) { throw 'The statistics file must contain a dictionary.' }
        if (-not $ImportedData.Contains('Statistics')) {
            $ExportData.Statistics = $ImportedData
        } else {
            $ExportData = $ImportedData
        }
    }
    foreach ($E in $GageConfiguration) {
        if (-not $ExportData['Statistics'].Contains($E.Date)) { $ExportData['Statistics'][$E.Date] = [ordered] @{} }
        $ExportData['Statistics'][$E.Date].Date = $E.Date
        $ExportData['Statistics'][$E.Date][$E.Label] = $E.Value
    }
    $ExportData
}
