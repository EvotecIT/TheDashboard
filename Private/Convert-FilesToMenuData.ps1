function Convert-FilesToMenuData {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $Folders,
        [System.Collections.IDictionary] $Replacements
    )
    Write-Color -Text '[i]', "[TheDashboard] ", 'Creating Menu', ' [Informative] ' -Color Yellow, DarkGray, Yellow, DarkGray, Magenta
    foreach ($FolderName in $Folders.Keys) {
        $Folder = $Folders[$FolderName]
        $FilesInFolder = Get-ChildItem -LiteralPath $Folders[$FolderName].Path -ErrorAction SilentlyContinue -Filter *.html | Sort-Object -Property Name
        foreach ($File in $FilesInFolder) {
            $Href = "$($Folders[$FolderName].Url)/$($File.Name)"

            $MenuName = $File.BaseName
            if ($Folder.ReplacementsGlobal -eq $true) {
                foreach ($Replace in $Replacements.BeforeSplit.Keys) {
                    $MenuName = $MenuName.Replace($Replace, $Replacements.BeforeSplit[$Replace])
                }
                $Splitted = $MenuName -split $Replacements.SplitOn
                if ($Replacements.AddSpaceToName) {
                    $Name = Format-AddSpaceToSentence -Text $Splitted[0]
                } else {
                    $Name = $Splitted[0]
                }
                foreach ($Replace in $Replacements.AfterSplit.Keys) {
                    $Name = $Name.Replace($Replace, $Replacements.AfterSplit[$Replace])
                }
            } else {
                foreach ($Replace in $Folder.Replacements.BeforeSplit.Keys) {
                    $MenuName = $MenuName.Replace($Replace, $Folder.Replacements.BeforeSplit[$Replace])
                }
                $Splitted = $MenuName -split $Folder.Replacements.SplitOn
                if ($Folder.Replacements.AddSpaceToName) {
                    $Name = Format-AddSpaceToSentence -Text $Splitted[0]
                } else {
                    $Name = $Splitted[0]
                }
                foreach ($Replace in $Folder.Replacements.AfterSplit.Keys) {
                    $Name = $Name.Replace($Replace, $Folder.Replacements.AfterSplit[$Replace])
                }
            }
            if ($Name -and $Splitted[1]) {
                [ordered] @{
                    Name     = $Name
                    NameDate = $Splitted[1]
                    Href     = $Href
                    FileName = "$($Folder.Url)_$($File.Name)"
                    Menu     = $FolderName
                    Date     = $File.LastWriteTime
                }
            } else {
                Write-Color -Text "[e]", "[TheDashboard] ", "Creating Menu ", "[error] ", "Couldn't create menu item for $($File.FullName)" -Color Red, DarkGray, Red, DarkGray, Red
            }
        }
    }
}