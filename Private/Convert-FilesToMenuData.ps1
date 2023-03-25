function Convert-FilesToMenuData {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $Folders,
        [System.Collections.IDictionary] $Replacements
    )
    Write-Color -Text '[i]', "[TheDashboard] ", 'Creating Menu from files', ' [Informative] ' -Color Yellow, DarkGray, Yellow, DarkGray, Magenta
    foreach ($FolderName in $Folders.Keys) {
        $Folder = $Folders[$FolderName]
        $FilesInFolder = Get-ChildItem -LiteralPath $Folders[$FolderName].Path -ErrorAction SilentlyContinue -Filter *.html | Sort-Object -Property Name

        Write-Color -Text '[i]', "[TheDashboard] ", "Creating Menu from files in folder ", "'$FolderName'", " files in folder ", $($FilesInFolder.Count), ' [Informative] ' -Color Yellow, DarkGray, Yellow, Magenta, Yellow, Magenta, DarkGray
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
                $NameDate = $Splitted[1]
                $Type = 'global replacements'
            } elseif ($Folder.Replacements) {
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
                $NameDate = $Splitted[1]
                $Type = 'folder replacements'
            } else {
                $Name = $MenuName
                $NameDate = $MenuName
                $Type = 'no replacements applied'
            }
            if ($Name -and $NameDate) {
                [ordered] @{
                    Name     = $Name
                    NameDate = $NameDate
                    Href     = $Href
                    FileName = "$($Folder.Url)_$($File.Name)"
                    Menu     = $FolderName
                    Date     = $File.LastWriteTime
                }
            } else {
                Write-Color -Text "[e]", "[TheDashboard] ", "Creating Menu ", "[error] ", "Couldn't create menu item for $($File.FullName). Problem with $Type" -Color Red, DarkGray, Red, DarkGray, Red
            }
        }
    }
}