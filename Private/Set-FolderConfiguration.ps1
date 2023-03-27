function Set-FolderConfiguration {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary]$Folders,
        [Array] $FoldersConfiguration
    )
    foreach ($Folder in $FoldersConfiguration) {
        if (-not $Folder.Name -and $Folder.UrlName) {
            $Folder.Name = $Folder.UrlName
        } elseif (-not $Folder.UrlName -and $Folder.Name) {
            $Folder.Url = $Folder.Name
        }
        $Folders[$Folder.Name] = $Folder
    }
}