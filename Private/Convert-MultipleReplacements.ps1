function Convert-MultipleReplacements {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $Replacements,
        [Array] $ReplacementConfiguration
    )

    if (-not $Replacements) {
        $ReplacementSetting = [ordered] @{
            SplitOn        = $null
            BeforeSplit    = [ordered] @{}
            AfterSplit     = [ordered] @{}
            AddSpaceToName = $null
        }
    } else {
        $ReplacementSetting = $Replacements
    }


    foreach ($Replacement in $ReplacementConfiguration) {
        Remove-EmptyValue -Hashtable $Replacement
        foreach ($R in $Replacement.Keys) {
            if ($R -eq 'SplitOn') {
                $ReplacementSetting['SplitOn'] = $Replacement[$R]
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
                $ReplacementSetting['AddSpaceToName'] = $Replacement[$R]
            }
        }
    }
    $ReplacementSetting
}