function New-DashboardReplacement {
    <#
    .SYNOPSIS
    Defines display-name transformations for dashboard report filenames.

    .DESCRIPTION
    Applies before-split replacements, optional splitting, selected filename parts,
    sentence formatting, and final replacements to report labels. These settings do
    not merge original report identities. Ordered replacement maps retain their declared
    order; unordered maps use deterministic key ordering.

    .PARAMETER SplitOn
    Regular expression used to split the filename stem, for example '_' or '[_-]'.
    Without splitting, a recognized trailing report timestamp is omitted from the label.

    .PARAMETER BeforeSplit
    Replacement dictionaries applied before splitting and naming-rule matching.

    .PARAMETER BeforeRemoveChars
    Literal text removed from the selected name before sentence formatting. Splitting
    and part selection happen first; use BeforeSplit to change the name before splitting.

    .PARAMETER AfterSplit
    Replacement dictionaries applied after sentence formatting.

    .PARAMETER AddSpaceToName
    Adds spaces around the word boundaries recognized by the sentence formatter.

    .PARAMETER AfterSplitPositionName
    A zero-based position, array of positions, or dictionary mapping filename patterns
    to positions. Negative positions count from the end. Patterns match after BeforeSplit
    replacements. Ordered maps select the first specific match; '*' is always fallback.
    Unordered maps prefer the most specific pattern and reject equally specific conflicting
    rules. Out-of-range positions are errors.

    .PARAMETER AfterRemoveChars
    Literal text removed after sentence formatting and before AfterSplit replacements.

    .PARAMETER AfterUpperChars
    Words or text fragments converted to uppercase during sentence formatting.

    .PARAMETER AfterRemoveDoubleSpaces
    Collapses repeated whitespace during sentence formatting.

    .PARAMETER ReplaceCaseInsenstive
    Applies BeforeSplit and AfterSplit replacement keys without case sensitivity.
    The parameter retains its existing spelling for compatibility.

    .PARAMETER ReplaceSkipRegex
    Treats replacement keys as regular expressions when ReplaceCaseInsenstive is enabled.
    Without this switch, case-insensitive replacement keys are escaped as literal text.
    Case-sensitive replacements use literal string replacement.

    .EXAMPLE
    New-DashboardReplacement -SplitOn '_' -BeforeSplit @{ 'GPO' = '' } -AfterSplit @{ 'BlockedInheritance' = 'Blocked Inheritance' } -AddSpaceToName

    Removes GPO text, selects the first underscore-delimited part, and formats the label.

    .EXAMPLE
    New-DashboardReplacement -SplitOn '_' -AfterSplitPositionName ([ordered] @{
        'Inventory-*' = 0, 1
        '*'           = 0
    })

    Selects two parts for Inventory reports and the first part for other reports.
    Using '_' preserves hyphens inside the selected part.

    .OUTPUTS
    A replacement configuration record consumed by Start-TheDashboard or New-DashboardFolder.
    #>
    [alias('New-TheDashboardReplacement')]
    [CmdletBinding()]
    param(
        [string] $SplitOn,
        [Array] $BeforeSplit,
        [alias('RemoveCharsBefore')][string[]] $BeforeRemoveChars,
        [Array] $AfterSplit,
        [alias('AfterAddSpaceToName')][switch] $AddSpaceToName,
        [object] $AfterSplitPositionName,
        [alias('RemoveCharsAfter')][string[]] $AfterRemoveChars,
        [alias('ConvertToUpperChars')][string[]] $AfterUpperChars,
        [alias('RemoveDoubleSpaces')][switch] $AfterRemoveDoubleSpaces,
        [switch] $ReplaceCaseInsenstive,
        [switch] $ReplaceSkipRegex
    )

    $BeforeEntry = [ordered] @{}
    foreach ($Before in $BeforeSplit) {
        foreach ($Key in Get-DashboardReplacementKeys -Dictionary $Before) {
            $BeforeEntry[$Key] = $Before[$Key]
        }
    }
    $AfterEntry = [ordered] @{}
    foreach ($After in $AfterSplit) {
        foreach ($Key in Get-DashboardReplacementKeys -Dictionary $After) {
            $AfterEntry[$Key] = $After[$Key]
        }
    }

    $Replacements = [ordered] @{
        Type     = 'Replacement'
        Settings = @{
            SplitOn                 = if ($PSBoundParameters.ContainsKey('SplitOn')) {
                $SplitOn
            } else {
                $null
            }
            BeforeSplit             = if ($PSBoundParameters.ContainsKey('BeforeSplit')) {
                $BeforeEntry
            } else {
                $null
            }
            AfterSplit              = if ($PSBoundParameters.ContainsKey('AfterSplit')) {
                $AfterEntry
            } else {
                $null
            }
            AddSpaceToName          = if ($PSBoundParameters.ContainsKey('AddSpaceToName')) {
                $AddSpaceToName
            } else {
                $null
            }
            AfterSplitPositionName  = if ($PSBoundParameters.ContainsKey('AfterSplitPositionName')) {
                $AfterSplitPositionName
            } else {
                $null
            }
            AfterRemoveChars        = if ($PSBoundParameters.ContainsKey('AfterRemoveChars')) {
                $AfterRemoveChars
            } else {
                $null
            }
            AfterUpperChars         = if ($PSBoundParameters.ContainsKey('AfterUpperChars')) {
                $AfterUpperChars
            } else {
                $null
            }
            AfterRemoveDoubleSpaces = if ($PSBoundParameters.ContainsKey('AfterRemoveDoubleSpaces')) {
                $AfterRemoveDoubleSpaces
            } else {
                $null
            }
            BeforeRemoveChars       = if ($PSBoundParameters.ContainsKey('BeforeRemoveChars')) {
                $BeforeRemoveChars
            } else {
                $null
            }
            ReplaceCaseInsenstive   = if ($PSBoundParameters.ContainsKey('ReplaceCaseInsenstive')) {
                $ReplaceCaseInsenstive
            } else {
                $null
            }
            ReplaceSkipRegex        = if ($PSBoundParameters.ContainsKey('ReplaceSkipRegex')) {
                $ReplaceSkipRegex
            } else {
                $null
            }
        }
    }
    $Replacements
}
