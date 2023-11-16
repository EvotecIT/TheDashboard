function Remove-DiscardedReports {
    [CmdletBinding()]
    param(
        [Array] $FilePathsGenerated,
        [string] $FolderPath,
        [string] $Extension
    )

    #$FilePathsCurrent = Get-ChildItem -LiteralPath $FolderPath -File -Filter "*$($Extension)" | Select-Object -ExpandProperty FullName
    $FilePathsCurrent = Get-ChildItem -LiteralPath $FolderPath -File -Filter "*$($Extension)" | Select-Object -ExpandProperty FullName
    foreach ($File in $FilePathsCurrent) {
        if ($File -notin $FilePathsGenerated) {
            Write-Color -Text '[i]', '[FILE ] ', "Removing discarded report: $File" -Color Yellow, DarkGray, Yellow
            Remove-Item -LiteralPath $File -Force
        }
    }
}