function Repair-ReportExtension {
    <#
    .SYNOPSIS
    This function renames the extension of files in a given directory.

    .DESCRIPTION
    The Repair-ReportExtension function is used to rename the extension of files in a specified directory from one extension to another.
    It's a part of the process of converting the reports to a SharePoint compatible format.

    .PARAMETER Path
    The path to the directory containing the files whose extensions are to be renamed.

    .PARAMETER ExtensionFrom
    The current extension of the files to be renamed.

    .PARAMETER ExtensionTo
    The new extension to be given to the files.

    .EXAMPLE
    Repair-ReportExtension -Path "C:\Reports" -ExtensionFrom ".html" -ExtensionTo ".aspx"
    This command renames the extension of all .html files in the C:\Reports directory to .aspx.

    .NOTES
    If a file with the new name already exists in the directory, the function will skip renaming that file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $Path,
        [Parameter(Mandatory)][string] $ExtensionFrom,
        [Parameter(Mandatory)][string] $ExtensionTo
    )
    # This script help converting HTML to ASPX files.
    # It's a part of the process of converting the reports to SharePoint compatible format.
    $Files = Get-ChildItem -Path $Path -File -Recurse -Include "*$ExtensionFrom"
    foreach ($File in $Files) {
        if ($File.Extension -eq $ExtensionFrom) {
            Write-Color -Text '[i]', "[TheDashboard] ", "Processing rename $($File.FullName) / $($File.LastWriteTime)" -Color Yellow
            # Rename extension to .aspx
            $NewName = $File.FullName -replace "$($ExtensionFrom)$", $ExtensionTo
            # Get directory from $File.FullName
            $ExpectedName = [io.path]::Combine($File.DirectoryName, $NewName)
            if (Test-Path -LiteralPath $ExpectedName) {
                Write-Color -Text "[i]", "[TheDashboard] ", "File already exists:$($ExpectedName). Skipping" -Color Yellow
                continue
            } else {
                Rename-Item -Path $File.FullName -NewName $NewName -Force
            }
        }
    }
}