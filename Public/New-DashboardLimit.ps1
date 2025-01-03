function New-DashboardLimit {
    [CmdletBinding()]
    param(
        [string] $Name,
        [nullable[int]] $LimitItem,
        [nullable[DateTime]] $LimitDate,
        [nullable[int]] $LimitDays,
        [switch] $IncludeHistory,
        [nullable[DateTime]] $IncludeHistoryLimitDate,
        [nullable[int]] $IncludeHistoryLimitDays,
        [nullable[int]] $IncludeHistoryLimit
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
            IncludeHistory          = $IncludeHistory
            IncludeHistoryLimit     = $IncludeHistoryLimit
            IncludeHistoryLimitDate = $IncludeHistoryLimitDate
            IncludeHistoryLimitDays = $IncludeHistoryLimitDays
        }
    }

    Remove-EmptyValue -Hashtable $Limit.Settings
    $Limit
}