function Remove-DiscardedReports {
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
