function Set-FolderConfiguration {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary]$Folders,
        [Array] $FoldersConfiguration,
        [System.Collections.IDictionary]$FolderLimit
    )
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
}