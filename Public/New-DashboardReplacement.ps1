function New-DashboardReplacement {
    [alias('New-TheDashboardReplacement')]
    [CmdletBinding()]
    param(
        [string] $SplitOn,
        [Array] $BeforeSplit,
        [alias('RemoveCharsBefore')][string[]] $BeforeRemoveChars,
        [Array] $AfterSplit,
        [alias('AfterAddSpaceToName')][switch] $AddSpaceToName,
        [int[]] $AfterSplitPositionName,

        [alias('RemoveCharsAfter')][string[]] $AfterRemoveChars,
        [alias('ConvertToUpperChars')][string[]] $AfterUpperChars,
        [alias('RemoveDoubleSpaces')][switch] $AfterRemoveDoubleSpaces
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
            SplitOn                 = if ($PSBoundParameters.ContainsKey('SplitOn')) { $SplitOn } else { $null }
            BeforeSplit             = if ($PSBoundParameters.ContainsKey('BeforeSplit')) { $BeforeEntry } else { $null }
            AfterSplit              = if ($PSBoundParameters.ContainsKey('AfterSplit')) { $AfterEntry } else { $null }
            AddSpaceToName          = if ($PSBoundParameters.ContainsKey('AddSpaceToName')) { $AddSpaceToName } else { $null }
            AfterSplitPositionName  = if ($PSBoundParameters.ContainsKey('AfterSplitPositionName')) { $AfterSplitPositionName } else { $null }
            AfterRemoveChars        = if ($PSBoundParameters.ContainsKey('AfterRemoveChars')) { $AfterRemoveChars } else { $null }
            AfterUpperChars         = if ($PSBoundParameters.ContainsKey('AfterUpperChars')) { $AfterUpperChars } else { $null }
            AfterRemoveDoubleSpaces = if ($PSBoundParameters.ContainsKey('AfterRemoveDoubleSpaces')) { $AfterRemoveDoubleSpaces } else { $null }
            BeforeRemoveChars       = if ($PSBoundParameters.ContainsKey('BeforeRemoveChars')) { $BeforeRemoveChars } else { $null }
        }
    }
    $Replacements
}