function Get-FileEncoding {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Path
    )

    $byte = [System.IO.File]::ReadAllBytes($Path)
    if ($byte[0] -eq 0xef -and $byte[1] -eq 0xbb -and $byte[2] -eq 0xbf) {
        return 'UTF8BOM'
    } elseif ($byte[0] -eq 0xff -and $byte[1] -eq 0xfe) {
        return 'Unicode'
    } elseif ($byte[0] -eq 0xfe -and $byte[1] -eq 0xff) {
        return 'BigEndianUnicode'
    } elseif ($byte[0] -eq 0x2b -and $byte[1] -eq 0x2f -and $byte[2] -eq 0x76) {
        return 'UTF7'
    } else {
        # Check if the file contains any non-ASCII characters
        for ($i = 0; $i -lt $byte.Length; $i++) {
            if ($byte[$i] -gt 0x7F) {
                return 'UTF8'
            }
        }
        return 'ASCII'
    }
}


# This is a fix for a SharePoint error that occurs when a string contains "<%"
# - Sorry, something went wrong. An error occurred during the processing of /sites/TheDashboard/Shared Documents/Gpozaurr_GPOBrokenPartially_2024-03-27_025637.aspx. The server block is not well formed.
# The reports created by several scripts contain "<%" in the string, which is not allowed in SharePoint. This is used by the Enlighter.JS library and shows up when not using -Online switch.
# Since the enlighter.js library is put inside HTML directly it causes issues with SharePoint.
# The script will replace "<%" with "<-%" in all files with the .aspx extension in the Reports folder.

# look for <%, if it's part of this string
$SearchString = [regex]::Escape("_|:|@|#|<-|←|<:|<%|=|=>|⇒|>:")

# lets replace it with "<-%", while it won't work, it will fix SharePoint error
$ReplaceString = [regex]::Escape("_|:|@|#|<-|←|<:|<-%|=|=>|⇒|>:")

$Directory = "C:\Users\przemyslaw.klys\Downloads"
$ExtensionFrom = '.aspx'
$Files = Get-ChildItem -Path $Directory -File -Recurse -Include "*$ExtensionFrom"
foreach ($File in $Files) {
    if ($File.Extension -eq $ExtensionFrom) {
        $Encoding = Get-FileEncoding -Path $File.FullName
        # Replace "<%" with "<-%"
        $FileContent = Get-Content -Raw -Path $File.FullName -Encoding $Encoding
        if ($FileContent -match $SearchString) {
            Write-Color -Text "Replacing offensive characters in $($File.FullName)" -Color Green
            $FileContent -replace $SearchString, $ReplaceString | Set-Content -Path $File.FullName -Encoding $Encoding  #-WhatIf
        }
    }
}
