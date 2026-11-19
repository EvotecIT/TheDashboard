function New-DashboardLimit {
    <#
    .SYNOPSIS
    Sets limit rules (date, days, item count) for dashboard reports.

    .DESCRIPTION
    Creates a structured object defining limits for how many reports to keep,
    how many to store in history, and date-based handling when displaying files.

    .PARAMETER Name
    Specifies which reports the limit applies to.

    .PARAMETER LimitItem
    Limits how many newest files are kept before moving to history.

    .PARAMETER LimitDate
    Specifies date threshold for including files in the menu.

    .PARAMETER LimitDays
    Specifies how many days back reports are displayed.

    .PARAMETER OutdatedDays
    Marks the latest report in the menu when its report date is older than this number of days.
    The report remains available and its retention settings still apply.

    .PARAMETER IncludeHistory
    Indicates whether older files are added to a history list instead of excluded.

    .PARAMETER IncludeHistoryLimitDate
    Date threshold after which history entries should not be included.

    .PARAMETER IncludeHistoryLimitDays
    Number of days to preserve history entries.

    .PARAMETER IncludeHistoryLimit
    Limits how many history entries are kept.

    .EXAMPLE
    New-DashboardLimit -LimitItem 3 -LimitDays 10

    .EXAMPLE
    New-DashboardLimit -OutdatedDays 30
    Shows the age of current reports older than 30 days in the menu.

    .NOTES
    Part of TheDashboard module, used to configure file retention rules.
    #>
    [CmdletBinding()]
    param(
        [string] $Name,
        [nullable[int]] $LimitItem,
        [nullable[DateTime]] $LimitDate,
        [nullable[int]] $LimitDays,
        [switch] $IncludeHistory,
        [nullable[DateTime]] $IncludeHistoryLimitDate,
        [nullable[int]] $IncludeHistoryLimitDays,
        [nullable[int]] $IncludeHistoryLimit,
        [ValidateRange(1, [int]::MaxValue)][nullable[int]] $OutdatedDays
    )

    if (-not $Name) {
        $Name = '*'
    }

    if ($IncludeHistoryLimitDate -or $IncludeHistoryLimitDays -or $IncludeHistoryLimit) {
        $IncludeHistory = $true
    }

    $Limit = [ordered] @{
        Type     = 'FolderLimit'
        Settings = [ordered] @{
            Name                    = $Name
            LimitItem               = $LimitItem
            LimitDate               = $LimitDate
            LimitDays               = $LimitDays
            OutdatedDays            = $OutdatedDays
            IncludeHistory          = $IncludeHistory
            IncludeHistoryLimit     = $IncludeHistoryLimit
            IncludeHistoryLimitDate = $IncludeHistoryLimitDate
            IncludeHistoryLimitDays = $IncludeHistoryLimitDays
        }
    }

    Remove-EmptyValue -Hashtable $Limit.Settings
    $Limit
}
