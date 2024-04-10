function Repair-ReportContent {
    <#
    .SYNOPSIS
    This function helps to replace content in files with a specific extension in a specific directory with a new content.

    .DESCRIPTION
    This function helps to replace content in files with a specific extension in a specific directory with a new content.

    .PARAMETER Directory
    Parameter description

    .PARAMETER ExtensionFrom
    Parameter description

    .EXAMPLE
    $SearchString = "_|:|@|#|<-|←|<:|<%|=|=>|⇒|>:"
    $ReplaceString = "_|:|@|#|<-|←|<:|<-%|=|=>|⇒|>:"
    $Directory = "C:\Users\przemyslaw.klys\Downloads"

    Repair-ReportContent -Directory $Directory -Search $SearchString -Replace $ReplaceString -EscapeRegex

    .EXAMPLE
    $SearchString = '<meta http-equiv="Content-Security-Policy".*?/>'
    $ReplaceString = ''
    $Directory = "C:\Support\GitHub\TheDashboard\Examples\Reports\Security"

    Repair-ReportContent -Directory $Directory -Search $SearchString -Replace $ReplaceString

    .NOTES
    This is a fix for a SharePoint error that occurs when a string contains "<%"
    - Sorry, something went wrong. An error occurred during the processing of /sites/TheDashboard/Shared Documents/Gpozaurr_GPOBrokenPartially_2024-03-27_025637.aspx. The server block is not well formed.
    The reports created by several scripts contain "<%" in the string, which is not allowed in SharePoint. This is used by the Enlighter.JS library and shows up when not using -Online switch.
    Since the enlighter.js library is put inside HTML directly it causes issues with SharePoint.
    The script will replace "<%" with "<-%" in all files with the .aspx extension in the Reports folder.

    This is also a fix for PingCastle reports that contain characters that block it from hosting on Sharepoint or IIS (<meta http-equiv="Content-Security-Policy".*?/>)

    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [parameter(Mandatory)][string] $Directory,
        [string] $ExtensionFrom = '.aspx',
        [string] $Search,
        [string] $Replace,
        [switch] $EscapeRegex
    )

    if ($EscapeRegex) {
        $SearchString = [regex]::Escape($Search)
        $ReplaceString = [regex]::Escape($Replace)
    } else {
        $SearchString = $Search
        $ReplaceString = $Replace
    }

    $Files = Get-ChildItem -Path $Directory -File -Recurse -Include "*$ExtensionFrom"
    foreach ($File in $Files) {
        if ($File.Extension -eq $ExtensionFrom) {
            # Store original dates
            $originalCreationTime = $File.CreationTime
            $originalLastWriteTime = $File.LastWriteTime

            $Encoding = Get-FileEncoding -Path $File.FullName
            $FileContent = Get-Content -Raw -Path $File.FullName -Encoding $Encoding
            if ($FileContent -match $SearchString) {
                Write-Color -Text "Replacing wrong content in $($File.FullName) ($SearchString / $ReplaceString) / Encoding: $Encoding" -Color Green
                $FileContent -replace $SearchString, $ReplaceString | Set-Content -Path $File.FullName -Encoding $Encoding

                # Restore original dates
                (Get-Item $File.FullName).CreationTime = $originalCreationTime
                (Get-Item $File.FullName).LastWriteTime = $originalLastWriteTime
            }
        }
    }
}