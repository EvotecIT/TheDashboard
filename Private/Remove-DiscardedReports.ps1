function Remove-DiscardedReports {
    <#
    .SYNOPSIS
    Removes obsolete pages previously owned by this dashboard.

    .DESCRIPTION
    Preserves planned outputs and files absent from the previous ownership manifest.
    Owned filenames must be leaf names so cleanup cannot traverse other directories.

    .PARAMETER FilePathsGenerated
    Full paths of pages retained by the current generation.

    .PARAMETER FolderPath
    Dashboard output directory containing the owned pages.

    .PARAMETER OwnedFiles
    Leaf filenames read from the previous ownership manifest.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Array] $FilePathsGenerated,
        [string] $FolderPath,
        [Array] $OwnedFiles
    )
    $Keep = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($Path in $FilePathsGenerated) {
        $null = $Keep.Add([IO.Path]::GetFullPath($Path))
    }
    foreach ($Name in $OwnedFiles) {
        if (-not $Name -or [IO.Path]::GetFileName($Name) -ne $Name -or $Name -in @('.', '..')) {
            throw "Invalid owned dashboard filename '$Name'."
        }
        $Path = Join-Path $FolderPath $Name
        if (-not $Keep.Contains($Path) -and (Test-Path -LiteralPath $Path -PathType Leaf) -and $PSCmdlet.ShouldProcess($Path, 'Remove obsolete dashboard page')) {
            Remove-Item -LiteralPath $Path -ErrorAction Stop
        }
    }
}
