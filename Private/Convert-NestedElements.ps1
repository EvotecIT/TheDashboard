function Convert-NestedElements {
    <#
    .SYNOPSIS
    Executes the dashboard configuration and collects supported elements.

    .DESCRIPTION
    Adds gauges, folder settings, replacement settings, and global retention settings
    to the supplied collections. Collector failures and unsupported element types
    propagate to the caller. Custom collectors must respect the caller's preview preference.

    .PARAMETER Elements
    Configuration script block to execute.

    .PARAMETER GageConfiguration
    Mutable collection receiving gauge settings.

    .PARAMETER FoldersConfiguration
    Mutable collection receiving folder settings.

    .PARAMETER ReplacementConfiguration
    Mutable collection receiving replacement settings.

    .PARAMETER FolderLimit
    Mutable dictionary receiving the global retention settings.
    #>
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
            throw
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
            } elseif ($E.Type) {
                throw "Dashboard element '$($E.Type)' is not supported by Start-TheDashboard."
            }
        }

        $TimeLogElements = Stop-TimeLog -Time $TimeLogElements -Option OneLiner
        Write-Color -Text '[i]', "[TheDashboard] ", 'Executing nested elements (data gathering/conversions)', ' [Time to execute: ', $TimeLogElements, ']' -Color Yellow, DarkGray, Yellow, DarkGray, Magenta
    }
}
