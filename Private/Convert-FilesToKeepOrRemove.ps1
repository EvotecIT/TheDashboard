function Convert-FilesToKeepOrRemove {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Array] $FilePathsGenerated,
        [Array] $Files,
        [switch] $RemoveNotIncluded,
        [ValidateSet("RemoveItem", "DotNetDelete", "RecycleBin")]
        [string] $DeleteMethod = "RecycleBin"
    )
    [Array] $FullSummary = @(
        foreach ($File in $FilePathsGenerated) {
            [PSCustomObject] @{
                Type    = 'Dashboard'
                Path    = $File
                Include = $true
                Date    = (Get-Item -LiteralPath $File).LastWriteTime
                Status  = if ($Include) { 'Included' } else { 'Excluded' }
            }

            foreach ($File in $Files) {
                [PSCustomObject] @{
                    Type    = 'Report'
                    Path    = $File.FullPath
                    Include = $File.Include
                    Date    = $File.Date
                    Status  = if ($File.Include) { 'Included' } else { 'Excluded' }
                }
            }
        }
    )
    if ($RemoveNotIncluded) {
        foreach ($File in $FullSummary) {
            if (-not $File.Include) {
                Remove-FileItem -Paths $File.Path -DeleteMethod $DeleteMethod -WhatIf:$WhatIfPreference
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