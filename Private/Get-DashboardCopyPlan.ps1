function Get-DashboardCopyPlan {
    <#
    .SYNOPSIS
    Plans report and supporting-asset copies without changing files.

    .DESCRIPTION
    Scans each configured source for the selected extensions, preserves relative
    paths, and rejects different sources targeting the same destination. Identical
    source/destination pairs are deduplicated.

    .PARAMETER Folders
    Normalized folder configuration containing paths, extensions, CopyFrom, and MoveFrom.

    .PARAMETER Extension
    Dashboard page extension, including its leading dot.

    .PARAMETER OutputRoot
    Dashboard output directory. Configured report folders must be beneath it.

    .OUTPUTS
    Copy records with Folder, Source, Destination, and Move properties.
    #>
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $Folders,
        [string] $Extension,
        [string] $OutputRoot
    )
    $Destinations = @{}
    foreach ($FolderName in $Folders.Keys) {
        $Folder = $Folders[$FolderName]
        if ($OutputRoot) {
            $Root = [IO.Path]::GetFullPath($OutputRoot).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
            if (-not $Folder.Path.StartsWith($Root, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Report folder '$($Folder.Path)' must be beneath the dashboard output directory. Use CopyFrom for external reports."
            }
        }
        $Extensions = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($Ext in @($Extension) + @($Folder.Extension)) {
            if ($Ext) {
                $null = $Extensions.Add('.' + $Ext.TrimStart('.'))
            }
        }
        foreach ($Mode in @('CopyFrom', 'MoveFrom')) {
            foreach ($SourceRoot in $Folder[$Mode]) {
                $SourceRoot = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($SourceRoot).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
                foreach ($File in Get-ChildItem -LiteralPath $SourceRoot -File -Recurse -ErrorAction Stop) {
                    if (-not $Extensions.Contains($File.Extension)) {
                        continue
                    }
                    $Relative = $File.FullName.Substring($SourceRoot.Length)
                    $Destination = [IO.Path]::GetFullPath((Join-Path $Folder.Path $Relative))
                    if ($Destination -eq $File.FullName) {
                        continue
                    }
                    if ($Destinations.ContainsKey($Destination)) {
                        if ($Destinations[$Destination].Source -eq $File.FullName) {
                            continue
                        }
                        throw "Multiple report sources target '$Destination'."
                    }
                    $Destinations[$Destination] = [PSCustomObject] @{
                        Folder      = $FolderName
                        Source      = $File.FullName
                        Destination = $Destination
                        Move        = $Mode -eq 'MoveFrom'
                    }
                }
            }
        }
    }
    $Destinations.Values | Sort-Object Destination
}
