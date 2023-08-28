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
        $LimitsConfiguration = $Folders[$Entry.Menu].LimitsConfiguration
        if ($LimitsConfiguration) {
            $Limits = $LimitsConfiguration[$Entry.Name]
            if (-not $Limits) {
                if ($LimitsConfiguration['*']) {
                    $Limits = $LimitsConfiguration['*']
                } else {
                    $Limits = $null
                }
            }
        } else {
            $Limits = $null
        }
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
        if ($Limits.LimitItem) {
            if ($MenuBuilder[$Entry.Menu][$Entry.Name]['All'].Count -ge $Limits.LimitItem) {
                continue
            }
        } elseif ($Limits.LimitDate) {
            if ($Entry.Date -lt $Limits.LimitDate) {
                continue
            }
        }
        $MenuBuilder[$Entry.Menu][$Entry.Name]['All'].Add($Entry)
    }
    $MenuBuilder
}