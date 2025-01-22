function Convert-NestedElements {
    [CmdletBinding()]
    param(
        [ScriptBlock] $Elements,
        [System.Collections.Generic.List[System.Collections.IDictionary]] $GageConfiguration,
        [System.Collections.Generic.List[System.Collections.IDictionary]] $FoldersConfiguration,
        [System.Collections.Generic.List[System.Collections.IDictionary]] $ReplacementConfiguration,
        [System.Collections.IDictionary] $FolderLimit
    )

    if ($Elements) {
        $TimeLogElements = Start-TimeLog
        Write-Color -Text '[i]', "[TheDashboard] ", 'Executing nested elements (data gathering/conversions)', ' [Informative] ' -Color Yellow, DarkGray, Yellow, DarkGray, Magenta

        try {
            $OutputElements = & $Elements
        } catch {
            Write-Color -Text '[e]', "[TheDashboard] ", 'Failed to execute nested elements', ' [Error] ', $_.Exception.Message -Color Yellow, DarkGray, Yellow, DarkGray, Red
            return
        }
        foreach ($E in $OutputElements) {
            if ($E.Type -eq 'Gage') {
                $GageConfiguration.Add($E.Settings)
            } elseif ($E.Type -eq 'Folder') {
                $FoldersConfiguration.Add($E.Settings)
            } elseif ($E.Type -eq 'Replacement') {
                $ReplacementConfiguration.Add($E.Settings)
            } elseif ($E.Type -eq 'FolderLimit') {
                foreach ($Setting in $E.Settings.Keys) {
                    $FolderLimit[$Setting] = $E.Settings[$Setting]
                }
            }
        }

        $TimeLogElements = Stop-TimeLog -Time $TimeLogElements -Option OneLiner
        Write-Color -Text '[i]', "[TheDashboard] ", 'Executing nested elements (data gathering/conversions)', ' [Time to execute: ', $TimeLogElements, ']' -Color Yellow, DarkGray, Yellow, DarkGray, Magenta
    }
}