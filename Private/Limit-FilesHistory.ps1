function Limit-FilesHistory {
    <#
    .SYNOPSIS
    Marks an older report included only when it meets the history settings.

    .DESCRIPTION
    Updates the report's Include flag and adds it to the group's History collection
    when history is enabled and count, date, and age limits permit it. Does not move
    or delete files.

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
    $Entry.Include = $false
    if ($Limits.IncludeHistory) {
        if ($null -ne $Limits.IncludeHistoryLimit) {
            if ($MenuBuilder[$Entry.Menu][$Entry.Identity]['History'].Count -ge $Limits.IncludeHistoryLimit) {
                $Entry.Include = $false
                return
            }
        }
        if ($null -ne $Limits.IncludeHistoryLimitDate) {
            if ($Entry.Date -lt $Limits.IncludeHistoryLimitDate) {
                $Entry.Include = $false
                return
            }
        }
        if ($null -ne $Limits.IncludeHistoryLimitDays) {
            if ($Entry.Date -lt ($CurrentDate).AddDays(-$Limits.IncludeHistoryLimitDays)) {
                $Entry.Include = $false
                return
            }
        }
        $Entry.Include = $true
        $MenuBuilder[$Entry.Menu][$Entry.Identity]['History'].Add($Entry)
    }
}
