function Convert-FilesToMenu {
    [CmdletBinding()]
    param([System.Collections.IDictionary] $Folders, [Array] $Files, [System.Collections.IDictionary] $ExportData, [switch] $Force)
    $MenuBuilder = [ordered] @{}
    foreach ($Folder in $Folders.Keys) { $MenuBuilder[$Folder] = [ordered] @{} }
    $CurrentDate = Get-Date
    foreach ($Entry in $Files | Sort-Object @{ Expression = { $_.Date }; Descending = $true }, @{ Expression = { $_.FullPath } }) {
        $LimitsConfiguration = $Folders[$Entry.Menu].LimitsConfiguration
        $Limits = $null
        if ($LimitsConfiguration) {
            $Limits = $LimitsConfiguration[$Entry.Name]
            if (-not $Limits) { $Limits = $LimitsConfiguration[$Entry.OriginalName] }
            if (-not $Limits) { $Limits = $LimitsConfiguration['*'] }
        }
        $Group = $MenuBuilder[$Entry.Menu][$Entry.Identity]
        if (-not $Group) {
            $Group = @{ Current = $Entry; Full = [System.Collections.Generic.List[object]]::new(); History = [System.Collections.Generic.List[object]]::new() }
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
