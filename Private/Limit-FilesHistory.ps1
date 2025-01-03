function Limit-FilesHistory {
    <#
    .SYNOPSIS
    Controls how files are moved into history based on specified limits.

    .DESCRIPTION
    Checks and applies IncludeHistory settings, filtering by date or count.

    .PARAMETER MenuBuilder
    Contains the menu structure to which entries will be added.

    .PARAMETER Entry
    Represents the current file entry under evaluation.

    .PARAMETER Limits
    Holds data about various limits for item, days, and date filtering.

    .PARAMETER CurrentDate
    Specifies the current date for time-based comparisons.

    .EXAMPLE
    Limit-FilesHistory -MenuBuilder $Builder -Entry $File -Limits $Limits -CurrentDate (Get-Date)

    .NOTES
    Part of TheDashboard module, handles history-limit logic for file entries.
    #>
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $MenuBuilder,
        [PSCustomObject] $Entry,
        [System.Collections.IDictionary] $Limits,
        [DateTime] $CurrentDate
    )
    if ($Limits.IncludeHistory) {
        if ($Limits.IncludeHistoryLimit) {
            if ($MenuBuilder[$Entry.Menu][$Entry.Name]['History'].Count -ge $Limits.IncludeHistoryLimit) {
                return
            }
        } elseif ($Limits.IncludeHistoryLimitDate) {
            if ($Entry.Date -lt $Limits.IncludeHistoryLimitDate) {
                return
            }
        } elseif ($Limits.IncludeHistoryLimitDays) {
            if ($Entry.Date -lt ($CurrentDate).AddDays(-$Limits.IncludeHistoryLimitDays)) {
                return
            }
        }
        $Entry.Include = $true
        $MenuBuilder[$Entry.Menu][$Entry.Name]['History'].Add($Entry)
    }
}