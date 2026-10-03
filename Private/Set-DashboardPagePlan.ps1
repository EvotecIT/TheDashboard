function Set-DashboardPagePlan {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $MenuBuilder,
        [System.Collections.IDictionary] $Configuration,
        [System.Collections.IDictionary] $ExportData,
        [string] $HTMLPath,
        [switch] $Force
    )
    $Root = [IO.Path]::GetDirectoryName($HTMLPath)
    $Extension = [IO.Path]::GetExtension($HTMLPath)
    $Pages = [System.Collections.Generic.List[object]]::new()
    foreach ($Menu in $MenuBuilder.Keys) {
        foreach ($Identity in $MenuBuilder[$Menu].Keys) {
            $Group = $MenuBuilder[$Menu][$Identity]
            $Prefix = $Group.Current.MenuLink
            if ([string]::IsNullOrWhiteSpace($Prefix) -or $Prefix -match '[<>:"/\\|?*\x00-\x1f]' -or $Prefix -in @('.', '..')) {
                throw "Folder '$Menu' has an invalid UrlName '$Prefix'. Use a filename prefix without path separators."
            }
            $Label = $Group.Current.Name -replace '[<>:"/\\|?*\x00-\x1f ]', '_'
            $Pages.Add([PSCustomObject] @{ Entry = $Group.Current; Kind = 'Current'; Candidate = "${Prefix}_$Label$Extension"; Key = "$Menu/$Identity/current" })
            foreach ($Entry in $Group.Full) {
                $Pages.Add([PSCustomObject] @{ Entry = $Entry; Kind = 'Snapshot'; Candidate = $Entry.FileName; Key = "$Menu/$Identity/$($Entry.Href)" })
            }
        }
    }
    $Used = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $null = $Used.Add([IO.Path]::GetFileName($HTMLPath))
    foreach ($Collision in $Pages | Group-Object Candidate) {
        foreach ($Page in $Collision.Group | Sort-Object Key) {
            $Name = $Page.Candidate
            if ($Collision.Count -gt 1 -or $Used.Contains($Name)) {
                $Name = [IO.Path]::GetFileNameWithoutExtension($Name) + '_' + (Get-DashboardHash -Text $Page.Key).Substring(0, 12) + $Extension
            }
            if (-not $Used.Add($Name)) { throw "Generated page collision: '$Name'." }
            if ($Page.Kind -eq 'Current') { $Page.Entry.PageName = $Name }
            else { $Page.Entry.FileName = $Name }
        }
    }
    $Navigation = @(foreach ($Menu in $MenuBuilder.Keys) {
        foreach ($Identity in $MenuBuilder[$Menu].Keys) {
            $Entry = $MenuBuilder[$Menu][$Identity].Current
            [ordered] @{ Menu = $Menu; Name = $Entry.Name; PageName = $Entry.PageName }
        }
    })
    $Template = (Get-Command New-HTMLReport).ScriptBlock.ToString() + (Get-Command New-HTMLReportPage).ScriptBlock.ToString()
    $Context = Get-DashboardHash -Text (([ordered] @{ Schema = 2; Configuration = $Configuration; Navigation = $Navigation; Template = $Template } | ConvertTo-Json -Depth 30 -Compress))
    $Paths = [System.Collections.Generic.List[string]]::new()
    $Paths.Add($HTMLPath)
    foreach ($Menu in $MenuBuilder.Keys) {
        foreach ($Identity in $MenuBuilder[$Menu].Keys) {
            $Group = $MenuBuilder[$Menu][$Identity]
            $Data = [ordered] @{}
            foreach ($Kind in @('Current', 'Full', 'History')) {
                $Data[$Kind] = @($Group[$Kind] | Select-Object Name, Href, FileName, PageName, Date, LastWriteTimeUtc, Length)
            }
            $Group.Fingerprint = Get-DashboardHash -Text ($Context + ($Data | ConvertTo-Json -Depth 10 -Compress))
            $OldGroup = $null
            if ($ExportData.MenuBuilder -and $ExportData.MenuBuilder[$Menu]) { $OldGroup = $ExportData.MenuBuilder[$Menu][$Identity] }
            $Unchanged = -not $Force -and $OldGroup -and $OldGroup.Fingerprint -eq $Group.Fingerprint
            $CurrentPath = Join-Path $Root $Group.Current.PageName
            $Group.Current.SkipGeneration = $Unchanged -and (Test-Path -LiteralPath $CurrentPath -PathType Leaf)
            $Paths.Add($CurrentPath)
            foreach ($Entry in $Group.Full) {
                $Path = Join-Path $Root $Entry.FileName
                # Current is also the newest snapshot: use a separate flag for its two pages.
                $Entry | Add-Member -NotePropertyName SkipSnapshotGeneration -NotePropertyValue ($Unchanged -and (Test-Path -LiteralPath $Path -PathType Leaf)) -Force
                $Paths.Add($Path)
            }
        }
    }
    $Paths
}
