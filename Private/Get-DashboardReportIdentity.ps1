function Get-DashboardReportIdentity {
    <#
    .SYNOPSIS
    Derives a stable report identity and date from the original filename.

    .DESCRIPTION
    Removes a valid trailing yyyy-MM-dd_HHmmss or yyyy-MM-dd_HH_mm_ss timestamp before forming the identity.
    Other names use their complete stem and last-write time. PingCastle domain names
    retain the full domain, including hyphens.

    .PARAMETER File
    Original report file metadata, before display-name replacements.

    .OUTPUTS
    A record containing Identity, BaseName, Domain, and Date.
    #>
    [CmdletBinding()]
    param(
        [System.IO.FileInfo] $File
    )
    $BaseName = $File.BaseName
    $Date = $File.LastWriteTime
    if ($BaseName -match '^(?<report>.+)_(?<stamp>\d{4}-\d{2}-\d{2}_(?:\d{6}|\d{2}_\d{2}_\d{2}))$') {
        $ParsedDate = [datetime]::MinValue
        $Formats = [string[]] @('yyyy-MM-dd_HHmmss', 'yyyy-MM-dd_HH_mm_ss')
        if ([datetime]::TryParseExact($Matches.stamp, $Formats, [cultureinfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref] $ParsedDate)) {
            $BaseName = $Matches.report
            $Date = $ParsedDate
        }
    }
    $Domain = $null
    if ($BaseName -match '^PingCastle-Domain-(?<domain>.+)$') {
        $Domain = $Matches.domain
    }
    [PSCustomObject] @{
        Identity = $BaseName.ToLowerInvariant()
        BaseName = $BaseName
        Domain   = $Domain
        Date     = $Date
    }
}
