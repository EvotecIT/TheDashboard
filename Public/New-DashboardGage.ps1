function New-TheDashboardGage {
    [cmdletBinding()]
    param(
        [string] $Label,
        [int] $MinValue,
        [int] $MaxValue,
        [int] $Value,
        [DateTime] $Date
    )

    [ordered] @{
        Label    = $Label
        Value    = $Value
        Date     = $Date
        MinValue = $MinValue
        MaxValue = $MaxValue
    }
}