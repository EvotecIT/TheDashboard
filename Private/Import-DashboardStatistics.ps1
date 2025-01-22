function Import-DashboardStatistics {
    [CmdletBinding()]
    param(
        [string] $StatisticsPath
    )
    $TopStats = [ordered] @{}
    if ($StatisticsPath -and (Test-Path -LiteralPath $StatisticsPath)) {
        Write-Color -Text '[i]', "[TheDashboard] ", 'Importing Statistics', ' [Informative] ', $StatisticsPath -Color Yellow, DarkGray, Yellow, DarkGray, Magenta
        $TopStats = Import-Clixml -LiteralPath $StatisticsPath
    }
    foreach ($E in $GageConfiguration) {
        $TopStats[$E.Date] = [ordered] @{}
        $TopStats[$E.Date].Date = $E.Date
    }
    $TopStats
}