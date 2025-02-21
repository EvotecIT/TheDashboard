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

    .PARAMETER ExportData
    Dictionary containing exported data from previous runs.

    .PARAMETER Force
    Forces the regeneration of the menu.

    .EXAMPLE
    Convert-FilesToMenu -Folders $Folders -Files $FileList

    .NOTES
    Part of TheDashboard module, creates the navigation menu from report files.
    #>
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $Folders,
        [Array] $Files,
        [System.Collections.IDictionary] $ExportData,
        [switch] $Force
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
            $Entry.Include = $true
            $MenuBuilder[$Entry.Menu][$Entry.Name] = @{
                Current = $Entry
                Full    = [System.Collections.Generic.List[Object]]::new()
                History = [System.Collections.Generic.List[Object]]::new()
            }
        }
        if ($Entry.Include -ne $true) {
            if ($Limits.LimitItem) {
                if ($MenuBuilder[$Entry.Menu][$Entry.Name]['Full'].Count -ge $Limits.LimitItem) {
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
        $MenuBuilder[$Entry.Menu][$Entry.Name]['Full'].Add($Entry)
    }

    if ($Force) {
        return $MenuBuilder
    }

    # Lets compare if we need to regenerate the menu, as it's time consuming and potentially not needed, to reupload all those files
    if ($ExportData.MenuBuilder.Keys.Count -eq 0) {
        # We need to regenerate the menu fully, as this is first time we generated menu
        return $MenuBuilder
    }
    if ($MenuBuilder.Keys -and $ExportData.MenuBuilder.Keys -and $MenuBuilder.Keys.Count -ne $ExportData.MenuBuilder.Keys.Count) {
        # We need to regenerate the menu fully, as things don't match
        return $MenuBuilder
    }
    $Comparison = Compare-Object -ReferenceObject $MenuBuilder.Keys -DifferenceObject $ExportData.MenuBuilder.Keys
    if ($Comparison) {
        # We need to regenerate the menu fully, as things are different
        return $MenuBuilder
    }


    foreach ($Section in $MenuBuilder.Keys) {
        if ($ExportData.MenuBuilder[$Section].Count -ne $MenuBuilder[$Section].Count) {
            # We need to regenerate the menu fully, as things are different on section level
            return $MenuBuilder
        }
        $Comparison = Compare-Object -ReferenceObject $MenuBuilder[$Section].Keys -DifferenceObject $ExportData.MenuBuilder[$Section].Keys
        if ($Comparison) {
            # We need to regenerate the menu fully, as things are different on section level
            return $MenuBuilder
        }
    }

    foreach ($Section in $MenuBuilder.Keys) {
        foreach ($Name in $MenuBuilder[$Section].Keys) {
            $MenuData = $MenuBuilder[$Section][$Name]
            $MenuDataFromImport = $ExportData.MenuBuilder[$Section][$Name]
            #$MenuData

            $RegenerateNotRequired = $true
            $Comparison = Compare-Object -ReferenceObject $MenuData.Current -DifferenceObject $MenuDataFromImport.Current -Property Date, Name, Href
            if ($Comparison) {
                $RegenerateNotRequired = $false
            }
            $Comparison = Compare-Object -ReferenceObject $MenuData.Full -DifferenceObject $MenuDataFromImport.Full -Property Date, Name, Href
            if ($Comparison) {
                $RegenerateNotRequired = $false
            }
            $Comparison = Compare-Object -ReferenceObject $MenuData.History -DifferenceObject $MenuDataFromImport.History -Property Date, Name, Href
            if ($Comparison) {
                $RegenerateNotRequired = $false
            }
            if ($RegenerateNotRequired -eq $true) {
                $MenuData.Current.SkipGeneration = $true
                foreach ($Entry in $MenuData.Full) {
                    $Entry.SkipGeneration = $true
                }
                foreach ($Entry in $MenuData.History) {
                    $Entry.SkipGeneration = $true
                }
            }
        }
    }
    $MenuBuilder
}