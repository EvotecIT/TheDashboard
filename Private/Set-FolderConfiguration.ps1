function Set-FolderConfiguration {
    <#
    .SYNOPSIS
    Combines folder definitions and normalizes their effective settings.

    .DESCRIPTION
    Updates the supplied folder dictionary in place with configuration elements,
    absolute paths, naming defaults, and applicable global retention settings.

    .PARAMETER Folders
    Mutable dictionary of folder definitions supplied to Start-TheDashboard.

    .PARAMETER FoldersConfiguration
    Folder settings collected from New-DashboardFolder elements.

    .PARAMETER FolderLimit
    Global retention settings applied unless a folder disables global limits.
    #>
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $Folders,
        [Array] $FoldersConfiguration,
        [System.Collections.IDictionary] $FolderLimit
    )

    Write-Color -Text '[i]', "[TheDashboard] ", 'Setting Folder Configuration', ' [Informative] ' -Color Yellow, DarkGray, Yellow, DarkGray, Magenta

    foreach ($Folder in $FoldersConfiguration) {
        if (-not $Folder.Name -and $Folder.Url) {
            $Folder.Name = $Folder.Url
        } elseif (-not $Folder.Url -and $Folder.Name) {
            $Folder.Url = $Folder.Name
        }

        if ($FolderLimit -and $FolderLimit.Name -and -not $Folder.DisableGlobalLimits) {
            $Folder.LimitsConfiguration[$FolderLimit.Name] = $FolderLimit
        }
        $Folders[$Folder.Name] = $Folder
    }
    foreach ($Name in $Folders.Keys) {
        $Folder = $Folders[$Name]
        $Folder.Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Folder.Path)
        if (-not $Folder.Name) {
            $Folder.Name = $Name
        }
        if (-not $Folder.Url) {
            $Folder.Url = $Name
        }
        if (-not $Folder.Contains('ReplacementsGlobal')) {
            $Folder.ReplacementsGlobal = $true
        }
        if (-not $Folder.LimitsConfiguration) {
            $Folder.LimitsConfiguration = [ordered] @{}
        }
        if ($FolderLimit -and $FolderLimit.Name -and -not $Folder.DisableGlobalLimits) {
            $Folder.LimitsConfiguration[$FolderLimit.Name] = $FolderLimit
        }
    }
}
