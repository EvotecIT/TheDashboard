function Limit-FilesHistory {
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