function Convert-DashboardReportName {
    [CmdletBinding()]
    param([string] $Name, [System.Collections.IDictionary] $Replacements)
    $DebugData = [ordered] @{ MenuName = $Name }
    foreach ($Key in Get-DashboardReplacementKeys -Dictionary $Replacements.BeforeSplit) {
        if ($Replacements.ReplaceCaseInsenstive) {
            $Pattern = if ($Replacements.ReplaceSkipRegex) { $Key } else { [regex]::Escape($Key) }
            $Name = $Name -ireplace $Pattern, $Replacements.BeforeSplit[$Key]
        } else { $Name = $Name.Replace($Key, $Replacements.BeforeSplit[$Key]) }
    }
    $DebugData.MenuNameStep2AfterBeforeSplitReplacements = $Name
    if ($Replacements.SplitOn) {
        $Parts = $Name -split $Replacements.SplitOn
        $Positions = @(Get-DashboardNamePositions -Name $Name -Rules $Replacements.AfterSplitPositionName)
        $Name = (@(foreach ($Position in $Positions) {
            $Index = 0
            if (-not [int]::TryParse([string] $Position, [ref] $Index) -or $Index -ge $Parts.Count -or $Index -lt -$Parts.Count) {
                throw "Naming position '$Position' is outside the $($Parts.Count) parts of '$Name'."
            }
            $Parts[$Index]
        })) -join ' '
        $DebugData.SplitPosition = $Positions -join ', '
    }
    $DebugData.MenuNameStep3AfterSplittingPosition = $Name
    if ($Replacements) {
        $Format = @{
            Text = $Name; RemoveCharsBefore = $Replacements.BeforeRemoveChars
            RemoveCharsAfter = $Replacements.AfterRemoveChars; RemoveDoubleSpaces = $Replacements.AfterRemoveDoubleSpaces
            MakeWordsUpperCase = $Replacements.AfterUpperChars; DisableAddingSpace = -not $Replacements.AddSpaceToName
        }
        $Name = Format-StringToSentence @Format
    }
    $DebugData.MenuNameStep4AfterFormat = $Name
    foreach ($Key in Get-DashboardReplacementKeys -Dictionary $Replacements.AfterSplit) {
        if ($Replacements.ReplaceCaseInsenstive) {
            $Pattern = if ($Replacements.ReplaceSkipRegex) { $Key } else { [regex]::Escape($Key) }
            $Name = $Name -ireplace $Pattern, $Replacements.AfterSplit[$Key]
        } else { $Name = $Name.Replace($Key, $Replacements.AfterSplit[$Key]) }
    }
    if ([string]::IsNullOrWhiteSpace($Name)) { throw 'Naming rules produced an empty report label.' }
    $DebugData.MenuNameFinal = $Name
    [PSCustomObject] @{ Name = $Name; Debug = [PSCustomObject] $DebugData }
}
