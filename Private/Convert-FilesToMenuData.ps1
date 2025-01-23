function Convert-FilesToMenuData {
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
            $Href = "$($RelativeFolder)/$($File.Name)"

            $MenuName = $File.BaseName
            if ($Folder.ReplacementsGlobal -eq $true) {
                foreach ($Replace in $Replacements.BeforeSplit.Keys) {
                    $MenuName = $MenuName.Replace($Replace, $Replacements.BeforeSplit[$Replace])
                }
                if ($Replacements.SplitOn) {
                    $Splitted = $MenuName -split $Replacements.SplitOn
                    if ($null -ne $Replacements.AfterSplitPositionName) {
                        $PositionPlace = @(0)
                        $Name = ''
                        if ($Replacements.AfterSplitPositionName -is [System.Collections.IDictionary]) {
                            foreach ($FileNameToFind in $Replacements.AfterSplitPositionName.Keys) {
                                [Array] $PositionPlace = $Replacements.AfterSplitPositionName[$FileNameToFind]
                                if ($MenuName -like $FileNameToFind) {
                                    break
                                }
                            }
                        } else {
                            [Array] $PositionPlace = $Replacements.AfterSplitPositionName
                        }
                        $NameParts = foreach ($Position in $PositionPlace) {
                            $Splitted[$Position]
                        }
                        $Name = $NameParts -join ' '
                    } else {
                        $Name = $Splitted[0]
                    }
                } else {
                    $Name = $MenuName
                }

                $formatStringToSentenceSplat = @{
                    Text               = $Name
                    RemoveCharsBefore  = $Replacements.BeforeRemoveChars
                    RemoveCharsAfter   = $Replacements.AfterRemoveChars
                    RemoveDoubleSpaces = $Replacements.AfterRemoveDoubleSpaces
                    MakeWordsUpperCase = $Replacements.AfterUpperChars
                    DisableAddingSpace = -not $Replacements.AddSpaceToName
                }
                $Name = Format-StringToSentence @formatStringToSentenceSplat

                foreach ($Replace in $Replacements.AfterSplit.Keys) {
                    $Name = $Name.Replace($Replace, $Replacements.AfterSplit[$Replace])
                }
                $Type = 'global replacements'
            } elseif ($Folder.Replacements) {
                foreach ($Replace in $Folder.Replacements.BeforeSplit.Keys) {
                    $MenuName = $MenuName.Replace($Replace, $Folder.Replacements.BeforeSplit[$Replace])
                }
                if ($Folder.Replacements.SplitOn) {
                    $Splitted = $MenuName -split $Folder.Replacements.SplitOn
                    if ($null -ne $Folder.Replacements.AfterSplitPositionName) {
                        $PositionPlace = @(0)
                        $Name = ''
                        if ($Folder.Replacements.AfterSplitPositionName -is [System.Collections.IDictionary]) {
                            foreach ($FileNameToFind in $Folder.Replacements.AfterSplitPositionName.Keys) {
                                [Array] $PositionPlace = $Folder.Replacements.AfterSplitPositionName[$FileNameToFind]
                                if ($MenuName -like $FileNameToFind) {
                                    break
                                }
                            }
                        } else {
                            [Array] $PositionPlace = $Folder.Replacements.AfterSplitPositionName
                        }
                        $NameParts = foreach ($Position in $PositionPlace) {
                            $Splitted[$Position]
                        }
                        $Name = $NameParts -join ' '
                    } else {
                        $Name = $Splitted[0]
                    }
                } else {
                    $Name = $MenuName
                }

                $formatStringToSentenceSplat = @{
                    Text               = $Name
                    RemoveCharsBefore  = $Folder.Replacements.BeforeRemoveChars
                    RemoveCharsAfter   = $Folder.Replacements.AfterRemoveChars
                    RemoveDoubleSpaces = $Folder.Replacements.AfterRemoveDoubleSpaces
                    MakeWordsUpperCase = $Folder.Replacements.AfterUpperChars
                    DisableAddingSpace = -not $Folder.Replacements.AddSpaceToName
                }

                $Name = Format-StringToSentence @formatStringToSentenceSplat

                foreach ($Replace in $Folder.Replacements.AfterSplit.Keys) {
                    $Name = $Name.Replace($Replace, $Folder.Replacements.AfterSplit[$Replace])
                }
                $Type = 'folder replacements'
            } else {
                $Name = $MenuName
                $Type = 'no replacements applied'
            }
            if ($Name) {
                [PSCustomObject] @{
                    Name           = $Name
                    Href           = $Href
                    FileName       = "$($Folder.Url)_$($File.Name)"
                    Menu           = $FolderName
                    MenuLink       = $Folder.Url
                    Date           = $File.LastWriteTime
                    # Useful for SharePoint upload capabilities
                    FullPath       = $File.FullName
                    # Include is used to determine if file should be included to copy/remove
                    Include        = $false
                    # SkipGeneration is used to determine if file for Dashboard should be regenerated or not
                    SkipGeneration = $false
                }
            } else {
                Write-Color -Text "[e]", "[TheDashboard] ", "Creating Menu ", "[error] ", "Couldn't create menu item for $($File.FullName). Problem with $Type" -Color Red, DarkGray, Red, DarkGray, Red
            }
        }
    }
}