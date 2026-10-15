function Convert-FilesToMenuData {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $Folders,
        [System.Collections.IDictionary] $Replacements,
        [string] $Extension,
        [string] $OutputRoot,
        [Array] $CopyPlan,
        [switch] $Pretend
    )
    $Entries = [System.Collections.Generic.List[object]]::new()
    foreach ($FolderName in $Folders.Keys) {
        $Folder = $Folders[$FolderName]
        $FolderPath = [IO.Path]::GetFullPath($Folder.Path).TrimEnd('\', '/')
        if ($OutputRoot) {
            $Root = [IO.Path]::GetFullPath($OutputRoot).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
            if (-not $FolderPath.StartsWith($Root, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Report folder '$FolderPath' must be beneath the dashboard output directory. Use CopyFrom for external reports."
            }
        }
        $FolderRoot = $FolderPath + [IO.Path]::DirectorySeparatorChar
        $FolderCopies = @($CopyPlan | Where-Object { $_.Destination.StartsWith($FolderRoot, [StringComparison]::OrdinalIgnoreCase) })
        $Inputs = @{}
        if (Test-Path -LiteralPath $FolderPath -PathType Container) {
            foreach ($File in Get-ChildItem -LiteralPath $FolderPath -File -Filter "*$Extension" -ErrorAction Stop) {
                $Inputs[$File.Name] = $File
            }
        } elseif (-not ($Pretend -and $FolderCopies.Count)) {
            throw "Report folder '$FolderPath' does not exist."
        }
        if ($Pretend) {
            foreach ($Copy in $FolderCopies | Where-Object { [IO.Path]::GetDirectoryName($_.Destination) -eq $FolderPath -and [IO.Path]::GetExtension($_.Destination) -eq $Extension }) {
                $Inputs[[IO.Path]::GetFileName($Copy.Destination)] = Get-Item -LiteralPath $Copy.Source -ErrorAction Stop
            }
        }
        foreach ($File in $Inputs.Values | Sort-Object Name) {
            $Identity = Get-DashboardReportIdentity -File $File
            $Settings = if ($Folder.ReplacementsGlobal) {
                $Replacements
            } else {
                $Folder.Replacements
            }
            $InputName = if ($Settings.SplitOn) {
                $File.BaseName
            } else {
                $Identity.BaseName
            }
            $Label = Convert-DashboardReportName -Name $InputName -Replacements $Settings
            $Name = $Label.Name
            if ($Identity.Domain -and ($Name -in @('Domain', 'PingCastle', 'Ping Castle') -or $Name -match '^Domain [^ ]+$')) {
                $Name = "Domain $($Identity.Domain)"
            }
            $FullPath = Join-Path $FolderPath $File.Name
            if ($OutputRoot) {
                $Href = ([uri] $Root).MakeRelativeUri([uri] $FullPath).ToString()
            } else {
                $Href = "$(Split-Path $FolderPath -Leaf)/$([uri]::EscapeDataString($File.Name))"
            }
            $Entries.Add([PSCustomObject] @{
                    Identity         = $Identity.Identity
                    ReportBaseName   = $Identity.BaseName
                    Domain           = $Identity.Domain
                    Name             = $Name
                    OriginalName     = $Label.Name
                    Href             = $Href
                    FileName         = "$($Folder.Url)_$($File.Name)"
                    Menu             = $FolderName
                    MenuLink         = $Folder.Url
                    Date             = $Identity.Date
                    LastWriteTimeUtc = $File.LastWriteTimeUtc
                    Length           = $File.Length
                    FullPath         = $FullPath
                    Include          = $false
                    SkipGeneration   = $false
                    PageName         = $null
                    Debug            = $Label.Debug
                })
        }
    }
    # Labels are presentation only. Disambiguate labels without changing report identity.
    foreach ($Labels in $Entries | Group-Object Menu, Name) {
        if (@($Labels.Group.Identity | Sort-Object -Unique).Count -gt 1) {
            foreach ($Entry in $Labels.Group) {
                $Suffix = if ($Entry.Domain) {
                    $Entry.Domain
                } else {
                    $Entry.ReportBaseName
                }
                $Entry.Name = "$($Entry.Name) ($Suffix)"
            }
        }
    }
    $Entries
}
