function New-DashboardGage {
    <#
    .SYNOPSIS
    Adds a gauge to the dashboard overview.
    .PARAMETER Label
    Name displayed on the gauge and used in overall gauge history.
    .PARAMETER MinValue
    Lower end of the gauge scale. Defaults to zero.
    .PARAMETER MaxValue
    Upper end of the gauge scale.
    .PARAMETER Value
    Current metric value.
    .PARAMETER Date
    Date and time of the sample.
    .PARAMETER City
    Shows this gauge when its city is selected. Omit City to supply an overall
    gauge for All and include it in the Domain Summary chart.
    .EXAMPLE
    New-DashboardGage -Label Users -MaxValue 100 -Value 35 -Date (Get-Date) -City Warsaw
    #>
    [alias('New-TheDashboardGage')]
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $Label,
        [Parameter()][int] $MinValue,
        [Parameter(Mandatory)][int] $MaxValue,
        [Parameter(Mandatory)][int] $Value,
        [Parameter(Mandatory)][DateTime] $Date,
        [string] $City
    )

    $Settings = [ordered] @{
        Label    = $Label
        Value    = $Value
        Date     = $Date
        MinValue = $MinValue
        MaxValue = $MaxValue
    }
    if (-not [string]::IsNullOrWhiteSpace($City)) {
        $Settings.City = $City.Trim()
    }

    [ordered] @{
        Type     = 'Gage'
        Settings = $Settings
    }
}
