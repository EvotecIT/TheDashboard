function Get-DashboardReportIdentity {
    [CmdletBinding()]
    param([System.IO.FileInfo] $File)
    $BaseName = $File.BaseName
    $Date = $File.LastWriteTime
    if ($BaseName -match '^(?<report>.+)_(?<stamp>\d{4}-\d{2}-\d{2}_\d{6})$') {
        $ParsedDate = [datetime]::MinValue
        if ([datetime]::TryParseExact($Matches.stamp, 'yyyy-MM-dd_HHmmss', [cultureinfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref] $ParsedDate)) {
            $BaseName = $Matches.report
            $Date = $ParsedDate
        }
    }
    $Domain = $null
    if ($BaseName -match '^PingCastle-Domain-(?<domain>.+)$') { $Domain = $Matches.domain }
    [PSCustomObject] @{ Identity = $BaseName.ToLowerInvariant(); BaseName = $BaseName; Domain = $Domain; Date = $Date }
}
