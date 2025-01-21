function New-DashboardNotification {
    [CmdletBinding(DefaultParameterSetName = 'Report')]
    param(
        [Parameter(ParameterSetName = 'Report')][string] $Name,
        [Parameter(ParameterSetName = 'Report')][string] $Category,
        [string] $Type,
        [string] $Filter,
        [Parameter(Mandatory)][string] $EmailTo,
        [Parameter()][string] $EmailCC,
        [Parameter(Mandatory)][string] $EmailSubject
    )

    $Notification = [ordered] @{
        Type     = 'Notification'
        Settings = [ordered] @{
            Id           = [Guid]::NewGuid().ToString()
            Name         = $Name
            Category     = $Category
            Type         = $Type
            Filter       = $Filter
            EmailTo      = $EmailTo
            EmailCC      = $EmailCC
            EmailSubject = $EmailSubject
        }
    }
    Remove-EmptyValue -Hashtable $Notification
    $Notification
}