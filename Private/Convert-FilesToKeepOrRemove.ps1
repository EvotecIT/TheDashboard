function Convert-FilesToKeepOrRemove {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Array] $FilePathsGenerated,
        [Array] $Files,
        [Array] $SupportingFiles,
        [switch] $RemoveNotIncluded,
        [ValidateSet("RemoveItem", "DotNetDelete", "RecycleBin")]
        [string] $DeleteMethod = "RecycleBin"
    )
    [Array] $FullSummary = @(
        foreach ($File in $FilePathsGenerated) {
            try {
                $FileInfo = Get-Item -LiteralPath $File -ErrorAction Stop
                $Output = [PSCustomObject] @{
                    Type    = 'Dashboard'
                    Path    = $File
                    Include = $true
                    Date    = ($FileInfo).LastWriteTime
                    Status  = 'Included'
                }
            } catch {
                $Output = [PSCustomObject] @{
                    Type    = 'Dashboard'
                    Path    = $File
                    Include = $true
                    Date    = $null
                    Status  = 'Included (WhatIf)'
                }
            }
            if ($WhatIfPreference) {
                $Output.Status = 'Included (WhatIf)'
            }
            $Output
        }
        foreach ($Group in $Files | Group-Object FullPath) {
            $File = $Group.Group[0]
            $Included = @($Group.Group | Where-Object Include).Count -gt 0
            [PSCustomObject] @{
                Type    = 'Report'
                Path    = $File.FullPath
                Include = $Included
                Date    = $File.Date
                Status  = if ($Included) {
                    'Included'
                } else {
                    'Excluded'
                }
            }
        }
        foreach ($File in $SupportingFiles) {
            [PSCustomObject] @{
                Type    = 'Asset'
                Path    = $File.FullPath
                Include = $true
                Date    = $File.Date
                Status  = if ($WhatIfPreference) {
                    'Included (WhatIf)'
                } else {
                    'Included'
                }
            }
        }
    )
    if ($RemoveNotIncluded) {
        foreach ($File in $FullSummary) {
            if ($File.Type -eq 'Report' -and -not $File.Include) {
                Remove-FileItem -Paths $File.Path -DeleteMethod $DeleteMethod -WhatIf:$WhatIfPreference -ErrorAction Stop
                if ($WhatIfPreference) {
                    $File.Status = 'Removed (WhatIf)'
                } else {
                    $File.Status = 'Removed'
                }
            }
        }
    }
    $FullSummary
}
