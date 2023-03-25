function Set-FolderConfiguration {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary]$Folders,
        [Array] $FoldersConfiguration
    )
    foreach ($Folder in $FoldersConfiguration) {
        $Folders[$Folder.Name] = $Folder
    }
}