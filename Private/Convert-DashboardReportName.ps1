function Convert-DashboardReportName {
    <#
    .SYNOPSIS
    Applies the configured display-name transformations to a report name.

    .DESCRIPTION
    Applies before-split replacements, selected filename parts, sentence formatting,
    and after-split replacements. Invalid split positions and empty labels are errors.
    These transformations do not determine the report's identity.

    .PARAMETER Name
    Filename stem to transform, with or without a timestamp as chosen by the caller.

    .PARAMETER Replacements
    Effective global or folder-specific naming configuration.

    .OUTPUTS
    A record with the display Name and Debug values for the transformation steps.
    #>
    [CmdletBinding()]
    param(
        [string] $Name,
        [System.Collections.IDictionary] $Replacements
    )
    $DebugData = [ordered] @{
        MenuName = $Name
    }
    foreach ($Key in Get-DashboardReplacementKeys -Dictionary $Replacements.BeforeSplit) {
        if ($Replacements.ReplaceCaseInsenstive) {
            $Pattern = if ($Replacements.ReplaceSkipRegex) {
                $Key
            } else {
                [regex]::Escape($Key)
            }
            $Name = $Name -ireplace $Pattern, $Replacements.BeforeSplit[$Key]
        } else {
            $Name = $Name.Replace($Key, $Replacements.BeforeSplit[$Key])
        }
    }
    $DebugData.MenuNameStep2AfterBeforeSplitReplacements = $Name
    if ($Replacements.SplitOn) {
        $Parts = $Name -split $Replacements.SplitOn
        $Positions = @(Get-DashboardNamePositions -Name $Name -Rules $Replacements.AfterSplitPositionName)
        $Name = (@(foreach ($Position in $Positions) {
                    $Index = 0
                    if (-not [int]::TryParse([string] $Position, [ref] $Index) -or $Index -ge $Parts.Count -or $Index -lt - $Parts.Count) {
                        throw "Naming position '$Position' is outside the $($Parts.Count) parts of '$Name'."
                    }
                    $Parts[$Index]
                })) -join ' '
        $DebugData.SplitPosition = $Positions -join ', '
    }
    $DebugData.MenuNameStep3AfterSplittingPosition = $Name
    if ($Replacements) {
        $Format = @{
            Text               = $Name
            RemoveCharsBefore  = $Replacements.BeforeRemoveChars
            RemoveCharsAfter   = $Replacements.AfterRemoveChars
            RemoveDoubleSpaces = $Replacements.AfterRemoveDoubleSpaces
            MakeWordsUpperCase = $Replacements.AfterUpperChars
            DisableAddingSpace = -not $Replacements.AddSpaceToName
        }
        $Name = Format-StringToSentence @Format
    }
    $DebugData.MenuNameStep4AfterFormat = $Name
    foreach ($Key in Get-DashboardReplacementKeys -Dictionary $Replacements.AfterSplit) {
        if ($Replacements.ReplaceCaseInsenstive) {
            $Pattern = if ($Replacements.ReplaceSkipRegex) {
                $Key
            } else {
                [regex]::Escape($Key)
            }
            $Name = $Name -ireplace $Pattern, $Replacements.AfterSplit[$Key]
        } else {
            $Name = $Name.Replace($Key, $Replacements.AfterSplit[$Key])
        }
    }
    if ([string]::IsNullOrWhiteSpace($Name)) {
        throw 'Naming rules produced an empty report label.'
    }
    $DebugData.MenuNameFinal = $Name
    [PSCustomObject] @{
        Name  = $Name
        Debug = [PSCustomObject] $DebugData
    }
}
