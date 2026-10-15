function Copy-HTMLFiles {
    <#
    .SYNOPSIS
    Copies changed report inputs and assets from a validated copy plan.

    .DESCRIPTION
    Skips unchanged destinations and replaces changed files through a temporary file
    beside the destination. Preserves source last-write times. Move sources are left
    intact; Start-TheDashboard removes them only after successful publication.

    .PARAMETER Plan
    Copy records containing Source and Destination paths.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Array] $Plan
    )
    foreach ($Copy in $Plan) {
        $Source = Get-Item -LiteralPath $Copy.Source -ErrorAction Stop
        $Destination = Get-Item -LiteralPath $Copy.Destination -ErrorAction SilentlyContinue
        $Unchanged = $Destination -and $Source.Length -eq $Destination.Length -and $Source.LastWriteTimeUtc -eq $Destination.LastWriteTimeUtc
        if (-not $Unchanged -and $Destination -and $Source.Length -eq $Destination.Length) {
            $Unchanged = (Get-FileHash -LiteralPath $Source.FullName).Hash -eq (Get-FileHash -LiteralPath $Destination.FullName).Hash
        }
        if ($Unchanged -or -not $PSCmdlet.ShouldProcess($Copy.Destination, 'Copy report')) {
            continue
        }
        $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Copy.Destination))
        $Temporary = $Copy.Destination + '.' + [guid]::NewGuid().ToString('N') + '.tmp'
        try {
            [IO.File]::Copy($Copy.Source, $Temporary, $false)
            [IO.File]::SetLastWriteTimeUtc($Temporary, $Source.LastWriteTimeUtc)
            if ([IO.File]::Exists($Copy.Destination)) {
                [IO.File]::Replace($Temporary, $Copy.Destination, [NullString]::Value)
            } else {
                [IO.File]::Move($Temporary, $Copy.Destination)
            }
        } finally {
            if ([IO.File]::Exists($Temporary)) {
                [IO.File]::Delete($Temporary)
            }
        }
        # MoveFrom sources are removed only after the complete dashboard publishes successfully.
    }
}
