function Import-DashboardStatistics {
    [CmdletBinding()]
    param(
        [string] $StatisticsPath
    )
    $ExportData = [ordered] @{
        MenuBuilder = [ordered] @{}
        Statistics  = [ordered] @{}
    }
    if ($StatisticsPath -and (Test-Path -LiteralPath $StatisticsPath)) {
        Write-Color -Text '[i]', "[TheDashboard] ", 'Importing Statistics', ' [Informative] ', $StatisticsPath -Color Yellow, DarkGray, Yellow, DarkGray, Magenta
        $ImportedData = Import-Clixml -LiteralPath $StatisticsPath
        if (-not $ImportedData.Statistics) {
            $ExportData.Statistics = $ImportedData
        } else {
            $ExportData = $ImportedData
        }
    }
    foreach ($E in $GageConfiguration) {
        $ExportData['Statistics'][$E.Date] = [ordered] @{}
        $ExportData['Statistics'][$E.Date].Date = $E.Date
    }
    $ExportData
}