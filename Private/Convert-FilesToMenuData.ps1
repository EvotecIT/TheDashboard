﻿function Convert-FilesToMenuData {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $Folders,
        [System.Collections.IDictionary] $Replacements,
        [string] $Extension
    )
    Write-Color -Text '[i]', "[TheDashboard] ", 'Creating Menu from files', ' [Informative] ' -Color Yellow, DarkGray, Yellow, DarkGray, Magenta
    foreach ($FolderName in $Folders.Keys) {
        $Folder = $Folders[$FolderName]
        $FilesInFolder = Get-ChildItem -LiteralPath $Folders[$FolderName].Path -ErrorAction SilentlyContinue -Filter "*$Extension" | Sort-Object -Property Name
        Write-Color -Text '[i]', "[TheDashboard] ", "Creating Menu from files in folder ", "'$FolderName'", " files in folder ", $($FilesInFolder.Count), ' [Informative] ' -Color Yellow, DarkGray, Yellow, Magenta, Yellow, Magenta, DarkGray
        foreach ($File in $FilesInFolder) {
            $RelativeFolder = Split-Path -Path $Folders[$FolderName].Path -Leaf
            #$Href = "$($Folders[$FolderName].Url)/$($File.Name)"
            $Href = "$($RelativeFolder)/$($File.Name)"

            $MenuName = $File.BaseName
            if ($Folder.ReplacementsGlobal -eq $true) {
                foreach ($Replace in $Replacements.BeforeSplit.Keys) {
                    $MenuName = $MenuName.Replace($Replace, $Replacements.BeforeSplit[$Replace])
                }
                if ($Replacements.SplitOn) {
                    $Splitted = $MenuName -split $Replacements.SplitOn
                    $Name = $Splitted[0]
                    #$NameDate = $Splitted[1]
                } else {
                    $Name = $MenuName
                    #$NameDate = $MenuName
                }
                if ($Replacements.AddSpaceToName) {
                    $Name = Format-AddSpaceToSentence -Text $Name
                }
                foreach ($Replace in $Replacements.AfterSplit.Keys) {
                    $Name = $Name.Replace($Replace, $Replacements.AfterSplit[$Replace])
                }
                # $NameDate = $Splitted[1]
                $Type = 'global replacements'
            } elseif ($Folder.Replacements) {
                foreach ($Replace in $Folder.Replacements.BeforeSplit.Keys) {
                    $MenuName = $MenuName.Replace($Replace, $Folder.Replacements.BeforeSplit[$Replace])
                }
                if ($Folder.Replacements.SplitOn) {
                    $Splitted = $MenuName -split $Folder.Replacements.SplitOn
                    $Name = $Splitted[0]
                    # $NameDate = $Splitted[1]
                } else {
                    $Name = $MenuName
                    #$NameDate = $MenuName
                }
                if ($Folder.Replacements.AddSpaceToName) {
                    $Name = Format-AddSpaceToSentence -Text $Name
                }
                foreach ($Replace in $Folder.Replacements.AfterSplit.Keys) {
                    $Name = $Name.Replace($Replace, $Folder.Replacements.AfterSplit[$Replace])
                }
                # $NameDate = $Splitted[1]
                $Type = 'folder replacements'
            } else {
                $Name = $MenuName
                #$NameDate = $MenuName
                $Type = 'no replacements applied'
            }
            if ($Name) {
                [ordered] @{
                    Name     = $Name
                    #NameDate = $NameDate
                    Href     = $Href
                    FileName = "$($Folder.Url)_$($File.Name)"
                    Menu     = $FolderName
                    MenuLink = $Folder.Url
                    Date     = $File.LastWriteTime
                }
            } else {
                Write-Color -Text "[e]", "[TheDashboard] ", "Creating Menu ", "[error] ", "Couldn't create menu item for $($File.FullName). Problem with $Type" -Color Red, DarkGray, Red, DarkGray, Red
            }
        }
    }
}