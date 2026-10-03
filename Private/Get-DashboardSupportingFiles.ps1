function Get-DashboardSupportingFiles {
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
            if ($Ext -and ('.' + $Ext.TrimStart('.')) -ne $Extension) { $null = $Extensions.Add('.' + $Ext.TrimStart('.')) }
        }
        if (-not $Extensions.Count) { continue }
        $Root = [IO.Path]::GetFullPath($Folder.Path).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
        if (Test-Path -LiteralPath $Folder.Path -PathType Container) {
            foreach ($File in Get-ChildItem -LiteralPath $Folder.Path -File -Recurse -ErrorAction Stop) {
                if ($Extensions.Contains($File.Extension)) {
                    $Assets[$File.FullName] = [PSCustomObject] @{ FullPath = $File.FullName; Date = $File.LastWriteTime }
                }
            }
        }
        if ($Pretend) {
            foreach ($Copy in $CopyPlan) {
                if ($Copy.Destination.StartsWith($Root, [StringComparison]::OrdinalIgnoreCase) -and $Extensions.Contains([IO.Path]::GetExtension($Copy.Destination))) {
                    $Source = Get-Item -LiteralPath $Copy.Source -ErrorAction Stop
                    $Assets[$Copy.Destination] = [PSCustomObject] @{ FullPath = $Copy.Destination; Date = $Source.LastWriteTime }
                }
            }
        }
    }
    $Assets.Values | Sort-Object FullPath
}
