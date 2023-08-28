function New-DashboardLimit {
    [CmdletBinding()]
    param(
        [string] $Name,
        [nullable[int]] $LimitItem,
        [nullable[DateTime]] $LimitDate
    )

    if (-not $Name) {
        $Name = '*'
    }
    $Limit = [ordered] @{
        Type     = 'FolderLimit'
        Settings = [ordered] @{
            Name      = $Name
            LimitItem = $LimitItem
            LimitDate = $LimitDate
        }
    }

    Remove-EmptyValue -Hashtable $Limit.Settings
    $Limit
}