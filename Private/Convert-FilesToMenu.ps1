function Convert-FilesToMenu {
    <#
    .SYNOPSIS
    Generates a structured menu from discovered report files.

    .DESCRIPTION
    Groups files by their original report identity within each configured folder.
    The newest version becomes the current report. Retention settings determine
    which additional versions appear as pages or retained history. Each input
    record's Include property is updated to reflect that decision.

    .PARAMETER Folders
    Dictionary defining menu sections and their retention limits.

    .PARAMETER Files
    Report records containing Identity, Menu, Date, FullPath, and display names.

    .PARAMETER ExportData
    Retained for existing callers. Cached-page comparison belongs to Set-DashboardPagePlan.

    .PARAMETER Force
    Retained for existing callers. Forced page generation belongs to Set-DashboardPagePlan.

    .EXAMPLE
    Convert-FilesToMenu -Folders $Folders -Files $FileList

    .OUTPUTS
    An ordered dictionary of menu sections and report groups with Current, Full,
    and History records.
    #>
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $Folders,
        [Array] $Files,
        [System.Collections.IDictionary] $ExportData,
        [switch] $Force
    )
    $MenuBuilder = [ordered] @{}
    foreach ($Folder in $Folders.Keys) {
        $MenuBuilder[$Folder] = [ordered] @{}
    }
    $CurrentDate = Get-Date
    foreach ($Entry in $Files | Sort-Object @{
            Expression = { $_.Date }
            Descending = $true
        }, @{
            Expression = { $_.FullPath }
        }) {
        $LimitsConfiguration = $Folders[$Entry.Menu].LimitsConfiguration
        $Limits = $null
        if ($LimitsConfiguration) {
            $Limits = $LimitsConfiguration[$Entry.Name]
            if (-not $Limits) {
                $Limits = $LimitsConfiguration[$Entry.OriginalName]
            }
            if (-not $Limits) {
                $Limits = $LimitsConfiguration['*']
            }
        }
        $Group = $MenuBuilder[$Entry.Menu][$Entry.Identity]
        if (-not $Group) {
            $Group = @{
                Current = $Entry
                Full    = [System.Collections.Generic.List[object]]::new()
                History = [System.Collections.Generic.List[object]]::new()
            }
            $MenuBuilder[$Entry.Menu][$Entry.Identity] = $Group
        } else {
            $Entry.Name = $Group.Current.Name
            if (($Limits.LimitItem -and $Group.Full.Count -ge $Limits.LimitItem) -or
                ($Limits.LimitDate -and $Entry.Date -lt $Limits.LimitDate) -or
                ($Limits.LimitDays -and $Entry.Date -lt $CurrentDate.AddDays(-$Limits.LimitDays))) {
                Limit-FilesHistory -MenuBuilder $MenuBuilder -Entry $Entry -Limits $Limits -CurrentDate $CurrentDate
                continue
            }
        }
        $Entry.Include = $true
        $Group.Full.Add($Entry)
    }
    $MenuBuilder
}
