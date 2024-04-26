function Convert-MultipleReplacements {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $Replacements,
        [Array] $ReplacementConfiguration
    )
    # otherwise try to build the replacement configuration
    if (-not $Replacements) {
        $ReplacementSetting = [ordered] @{
            SplitOn                 = $null
            BeforeSplit             = [ordered] @{}
            AfterSplit              = [ordered] @{}
            AddSpaceToName          = $null
            AfterSplitPositionName  = $null
            AfterRemoveChars        = $null
            AfterUpperChars         = $null
            AfterRemoveDoubleSpaces = $null
            BeforeRemoveChars       = $null
        }
    } else {
        $ReplacementSetting = $Replacements
    }


    foreach ($Replacement in $ReplacementConfiguration) {
        Remove-EmptyValue -Hashtable $Replacement
        foreach ($R in $Replacement.Keys) {
            if ($R -eq 'SplitOn') {
                if ($null -ne $Replacement[$R]) {
                    $ReplacementSetting['SplitOn'] = $Replacement[$R]
                }
            } elseif ($R -eq 'beforeSplit') {
                foreach ($Before in $Replacement[$R]) {
                    foreach ($Key in $Before.Keys) {
                        $ReplacementSetting['BeforeSplit'][$Key] = $Before[$Key]
                    }
                }
            } elseif ($R -eq 'afterSplit') {
                foreach ($After in $Replacement[$R]) {
                    foreach ($Key in $After.Keys) {
                        $ReplacementSetting['AfterSplit'][$Key] = $After[$Key]
                    }
                }
            } elseif ($R -eq 'addSpaceToName') {
                if ($null -ne $Replacement[$R]) {
                    $ReplacementSetting['AddSpaceToName'] = $Replacement[$R]
                }
            } elseif ($R -eq 'AfterSplitPositionName') {
                if ($null -ne $Replacement[$R]) {
                    $ReplacementSetting['AfterSplitPositionName'] = $Replacement[$R]
                }
            } else {
                if ($null -ne $Replacement[$R]) {
                    if ($Replacement[$R].GetType().Name -eq 'SwitchParameter') {
                        $ReplacementSetting[$R] = $Replacement[$R].IsPresent
                    } else {
                        $ReplacementSetting[$R] = $Replacement[$R]
                    }
                }
            }
        }
    }
    $ReplacementSetting
}