function New-DashboardReplacement {
    <#
    .SYNOPSIS
    Helps preparing Menu Names and Menu Entries for the dashboard from the file names

    .DESCRIPTION
    Helps preparing Menu Names and Menu Entries for the dashboard from the file names

    .PARAMETER SplitOn
    Character to split on, for example on '_' or in most cases [_-] which means either _ or -

    .PARAMETER BeforeSplit
    Dictionary of replacements to be done before splitting

    .PARAMETER BeforeRemoveChars
    Array of characters to remove from the name before splitting, such as specific prefixes or suffixes.

    .PARAMETER AfterSplit
    Dictionary of replacements to be done after splitting the file name.

    .PARAMETER AddSpaceToName
    Switch indicating whether to add spaces between words in the menu name.

    .PARAMETER AfterSplitPositionName
    Array indicating which positions to select from the split file name after splitting.

    .PARAMETER AfterRemoveChars
    Array of characters to remove from the name after splitting, such as specific unwanted characters.

    .PARAMETER AfterUpperChars
    Array of strings to convert to upper case after splitting.

    .PARAMETER AfterRemoveDoubleSpaces
    Switch indicating whether to remove double spaces from the formatted name.

    .PARAMETER ReplaceCaseInsenstive
    Switch indicating whether replacements should be case insensitive.

    .PARAMETER ReplaceSkipRegex
    Array of regex patterns to skip during the replacement process.

    .EXAMPLE
    An example of how to use the New-DashboardReplacement function.
    For example:
    ```powershell
    New-DashboardReplacement -SplitOn '_' -BeforeSplit @{ 'GPO' = '' } -AfterSplit @{ 'BlockedInheritance' = 'Blocked Inheritance' } -AddSpaceToName
    ```

    .NOTES
    The process of replacement is done in a specific order.
    - Before Split Replacements => to fix the name before splitting, say remove some parts we don't like
    - SplitOn => split on specific character or characters, for example on '_' or in most cases [_-] which means either _ or -
    - PositionName => Pick specific parts of the split based on the full file name after first replacements
    - FormatString => Format the string based on settings provided
    - After Split Replacements => Replacements after split

    The way it works is:
    - We take file 'GPOBlockedInheritance_2023-10-05_092149.aspx'
    - We first do BeforeSplit replacements:
        - It could be for example removing 'GPO' from the name or changing Inheritance to something else
    - We then split on specific character, for example on '_' or in most cases [_-] which means either _ or -
    - After splitting, we will select specific parts of the file name based on the split results, to create a formatted name for the output.
        - If we split on [_-] we get 'GPOBlockedInheritance', '2023', '10', '05', '092149.aspx'
        - However keep in mind we removed 'GPO' in BeforeSplit, so we would get 'BlockedInheritance', '2023', '10', '05', '092149.aspx'
        - So now we can select specific parts of the split, for example 0, 1, 2, 3, 4, 5
        - If we select 0, 1 we would get 'BlockedInheritance', '2023'
    - We then merge the selected parts into a single string, for example 'BlockedInheritance 2023' which will be our menu name
    - However at this point we also can do 'AddSpaceToName' which basically adds space between words, so 'BlockedInheritance 2023' becomes 'Blocked Inheritance 2023'
    - This step is necessary to improve readability and user experience.
    - However the way it works to add a space is to search for all high case letters and add space before them, so 'BlockedInheritance 2023' becomes 'Blocked Inheritance 2023'
    - This works fine for most cases, but sometimes we need to do additional replacements, for example 'GPO' becomes 'G P O', 'PingCastle' becomes 'Ping Castle'
    - We then do AfterSplit replacements, for example replacing 'G P O' with 'GPO' or 'Ping Castle' back to 'PingCastle'


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
            ReplaceCaseInsenstive   = if ($PSBoundParameters.ContainsKey('ReplaceCaseInsenstive')) { $ReplaceCaseInsenstive } else { $null }
            ReplaceSkipRegex        = if ($PSBoundParameters.ContainsKey('ReplaceSkipRegex')) { $ReplaceSkipRegex } else { $null }
        }
    }
    $Replacements
}