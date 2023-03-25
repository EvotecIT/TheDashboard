function New-DashboardGage {
    [alias('New-TheDashboardGage')]
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $Label,
        [Parameter()][int] $MinValue,
        [Parameter(Mandatory)][int] $MaxValue,
        [Parameter(Mandatory)][int] $Value,
        [Parameter(Mandatory)][DateTime] $Date
    )

    [ordered] @{
        Type     = 'Gage'
        Settings = [ordered] @{
            Label    = $Label
            Value    = $Value
            Date     = $Date
            MinValue = $MinValue
            MaxValue = $MaxValue
        }
    }
}