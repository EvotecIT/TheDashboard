function New-DashboardLimit {
    [CmdletBinding()]
    param(
        [parameter(Mandatory)][string] $Name,
        [nullable[int]] $LimitItem,
        [nullable[DateTime]] $LimitDate
    )

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