function Get-DashboardSupportingFiles {
    <#
    .SYNOPSIS
    Finds supporting assets that must accompany deployed reports.

    .DESCRIPTION
    Includes configured non-page extensions recursively without creating menu entries.
    Paths shared by multiple sections appear only once.

    .PARAMETER Folders
    Normalized report folders and their additional extensions.

    .PARAMETER Extension
    Dashboard page extension to exclude from supporting assets.

    .PARAMETER CopyPlan
    Planned source/destination pairs used to include assets during preview.

    .PARAMETER Pretend
    Includes planned destination paths even when they have not been copied yet.

    .OUTPUTS
    Asset records containing FullPath and Date.
    #>
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $Folders,
        [string] $Extension,
        [Array] $CopyPlan,
        [switch] $Pretend
    )
    $Assets = @{}
    foreach ($Folder in $Folders.Values) {
        $Extensions = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($Ext in $Folder.Extension) {
            if ($Ext -and ('.' + $Ext.TrimStart('.')) -ne $Extension) {
                $null = $Extensions.Add('.' + $Ext.TrimStart('.'))
            }
        }
        if (-not $Extensions.Count) {
            continue
        }
        $Root = [IO.Path]::GetFullPath($Folder.Path).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
        if (Test-Path -LiteralPath $Folder.Path -PathType Container) {
            foreach ($File in Get-ChildItem -LiteralPath $Folder.Path -File -Recurse -ErrorAction Stop) {
                if ($Extensions.Contains($File.Extension)) {
                    $Assets[$File.FullName] = [PSCustomObject] @{
                        FullPath = $File.FullName
                        Date     = $File.LastWriteTime
                    }
                }
            }
        }
        if ($Pretend) {
            foreach ($Copy in $CopyPlan) {
                if ($Copy.Destination.StartsWith($Root, [StringComparison]::OrdinalIgnoreCase) -and $Extensions.Contains([IO.Path]::GetExtension($Copy.Destination))) {
                    $Source = Get-Item -LiteralPath $Copy.Source -ErrorAction Stop
                    $Assets[$Copy.Destination] = [PSCustomObject] @{
                        FullPath = $Copy.Destination
                        Date     = $Source.LastWriteTime
                    }
                }
            }
        }
    }
    $Assets.Values | Sort-Object FullPath
}
