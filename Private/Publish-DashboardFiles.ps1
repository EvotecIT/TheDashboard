function Publish-DashboardFiles {
    <#
    .SYNOPSIS
    Publishes staged files and rolls back completed replacements after a failure.

    .DESCRIPTION
    Replaces each destination through a temporary file in the same directory.
    Existing files have backups until the batch completes. On failure, completed
    writes are reversed; failed rollback backups remain available for recovery.
    This does not provide a whole-site transaction across process termination.

    .PARAMETER Files
    Ordered records with Source and Destination paths. The caller determines
    publication order, including placing the landing page after its child pages.
    #>
    [CmdletBinding()]
    param(
        [Array] $Files
    )
    $Published = [System.Collections.Generic.List[object]]::new()
    $Committed = $false
    try {
        foreach ($File in $Files) {
            $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($File.Destination))
            $Temporary = $File.Destination + '.' + [guid]::NewGuid().ToString('N') + '.tmp'
            $Backup = $Temporary + '.bak'
            $Existed = [IO.File]::Exists($File.Destination)
            try {
                [IO.File]::Copy($File.Source, $Temporary, $false)
                if ($Existed) {
                    [IO.File]::Replace($Temporary, $File.Destination, $Backup)
                } else {
                    [IO.File]::Move($Temporary, $File.Destination)
                }
                $Published.Add([PSCustomObject] @{
                        Destination = $File.Destination
                        Backup      = $Backup
                        Existed     = $Existed
                    })
            } finally {
                if ([IO.File]::Exists($Temporary)) {
                    [IO.File]::Delete($Temporary)
                }
            }
        }
        $Committed = $true
    } catch {
        $Failure = $_
        $RollbackFailures = [System.Collections.Generic.List[string]]::new()
        for ($Index = $Published.Count - 1; $Index -ge 0; $Index--) {
            $Previous = $Published[$Index]
            try {
                if ($Previous.Existed) {
                    [IO.File]::Replace($Previous.Backup, $Previous.Destination, [NullString]::Value)
                } else {
                    [IO.File]::Delete($Previous.Destination)
                }
            } catch {
                $RollbackFailures.Add("$($Previous.Destination): $($_.Exception.Message); backup: $($Previous.Backup)")
            }
        }
        if ($RollbackFailures.Count) {
            throw "Publication failed: $($Failure.Exception.Message). Rollback needs recovery: $($RollbackFailures -join '; ')"
        }
        throw $Failure
    } finally {
        if ($Committed) {
            foreach ($Previous in $Published) {
                if ([IO.File]::Exists($Previous.Backup)) {
                    [IO.File]::Delete($Previous.Backup)
                }
            }
        }
    }
}
