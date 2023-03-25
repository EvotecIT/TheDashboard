function Convert-FilesToMenu {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $Folders,
        [Array] $Files
    )
    # Prepare menu based on files
    $MenuBuilder = [ordered] @{}
    # lets build top level based on folders to keep the order of menus
    foreach ($Folder in $Folders.Keys) {
        if (-not $MenuBuilder[$Folder]) {
            $MenuBuilder[$Folder] = [ordered] @{}
        }
    }
    # We now build menu from files
    foreach ($Entry in $Files) {
        if (-not $MenuBuilder[$Entry.Menu][$Entry.Name]) {
            $MenuBuilder[$Entry.Menu][$Entry.Name] = @{
                Current = $Entry
                All     = [System.Collections.Generic.List[Object]]::new()
            }
        } else {
            if ($MenuBuilder[$Entry.Menu][$Entry.Name]['Current'].Date -lt $Entry.Date) {
                $MenuBuilder[$Entry.Menu][$Entry.Name]['Current'] = $Entry

            }
        }
        $MenuBuilder[$Entry.Menu][$Entry.Name]['All'].Add($Entry)
    }
    $MenuBuilder
}