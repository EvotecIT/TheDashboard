function Convert-FilesToMenu {
    <#
    .SYNOPSIS
    Generates a structured menu from a collection of files and folders.

    .DESCRIPTION
    Builds ordered folders and file entries, applies filtering and history logic.

    .PARAMETER Folders
    Dictionary defining folder metadata and optional limits configuration.

    .PARAMETER Files
    Array of file data, each containing attributes such as Date, Menu, and Name.

    .EXAMPLE
    Convert-FilesToMenu -Folders $Folders -Files $FileList

    .NOTES
    Part of TheDashboard module, creates the navigation menu from report files.
    #>
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $Folders,
        [Array] $Files
    )
    $CurrentDate = Get-Date
    # Prepare menu based on files
    $MenuBuilder = [ordered] @{}
    # lets build top level based on folders to keep the order of menus
    foreach ($Folder in $Folders.Keys) {
        if (-not $MenuBuilder[$Folder]) {
            $MenuBuilder[$Folder] = [ordered] @{}
        }
    }
    # We now build menu from files
    foreach ($Entry in $Files | Sort-Object { $_.Date } -Descending) {
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
        # we start creating menu based on files
        if (-not $MenuBuilder[$Entry.Menu][$Entry.Name]) {
            Write-Verbose -Message "Creating menu for $($Entry.Menu) - $($Entry.Name)"
            $Entry.Include = $true
            $MenuBuilder[$Entry.Menu][$Entry.Name] = @{
                Current = $Entry
                All     = [System.Collections.Generic.List[Object]]::new()
                History = [System.Collections.Generic.List[Object]]::new()
            }
        }
        # if ($MenuBuilder[$Entry.Menu][$Entry.Name]['Current'].Date -lt $Entry.Date) {
        #     #$MenuBuilder[$Entry.Menu][$Entry.Name]['Current'].Include = $false
        #     $Entry.Include = $true
        #     $MenuBuilder[$Entry.Menu][$Entry.Name]['Current'] = $Entry
        # } else {
        #     if ($null -eq $Limits) {
        #         $Entry.Include = $true
        #     }
        # }

        if ($Entry.Include -ne $true) {
            if ($Limits.LimitItem) {
                if ($MenuBuilder[$Entry.Menu][$Entry.Name]['All'].Count -ge $Limits.LimitItem) {
                    $Entry.Include = $true
                    # User limited input in standard way, we just add it to history which will be treated differently
                    Limit-FilesHistory -MenuBuilder $MenuBuilder -Entry $Entry -Limits $Limits -CurrentDate $CurrentDate
                    continue
                }
            } elseif ($Limits.LimitDate) {
                if ($Entry.Date -lt $Limits.LimitDate) {
                    $Entry.Include = $true
                    # User limited input in standard way, we just add it to history which will be treated differently
                    Limit-FilesHistory -MenuBuilder $MenuBuilder -Entry $Entry -Limits $Limits -CurrentDate $CurrentDate
                    continue
                }
            } elseif ($Limits.LimitDays) {
                if ($Entry.Date -lt ($CurrentDate).AddDays(-$Limits.LimitDays)) {
                    $Entry.Include = $true
                    # User limited input in standard way, we just add it to history which will be treated differently
                    Limit-FilesHistory -MenuBuilder $MenuBuilder -Entry $Entry -Limits $Limits -CurrentDate $CurrentDate
                    continue
                }
            }
        }
        $Entry.Include = $true
        $MenuBuilder[$Entry.Menu][$Entry.Name]['All'].Add($Entry)
    }
    $MenuBuilder
}