function New-DashboardReplacement {
    [alias('New-TheDashboardReplacement')]
    [CmdletBinding()]
    param(
        [string] $SplitOn,
        [Array] $BeforeSplit,
        [Array] $AfterSplit,
        [switch] $AddSpaceToName
    )

    $BeforeEntry = [ordered] @{}
    foreach ($Before in $BeforeSplit) {
        foreach ($Key in $Before.Keys) {
            $BeforeEntry[$Key] = $Before[$Key]
        }
    }
    $AfterEntry = [ordered] @{}
    foreach ($After in $AfterSplit) {
        foreach ($Key in $After.Keys) {
            $AfterEntry[$Key] = $After[$Key]
        }
    }

    $Replacements = [ordered] @{
        Type     = 'Replacement'
        Settings = @{
            SplitOn        = if ($PSBoundParameters.ContainsKey('SplitOn')) { $SplitOn } else { $null }
            BeforeSplit    = if ($PSBoundParameters.ContainsKey('BeforeSplit')) { $BeforeEntry } else { $null }
            AfterSplit     = if ($PSBoundParameters.ContainsKey('AfterSplit')) { $AfterEntry } else { $null }
            AddSpaceToName = if ($PSBoundParameters.ContainsKey('AddSpaceToName')) { $AddSpaceToName } else { $null }
        }
    }
    $Replacements
}