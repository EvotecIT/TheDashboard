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

            $ResultsFile = [ordered] @{
                File     = $File.Name
                Href     = $Href
                MenuName = $MenuName
            }
            $ResultsFile['ReplaceCaseInsenstive'] = $Replacements.ReplaceCaseInsenstive
            $ResultsFile['ReplaceSkipRegex'] = $Replacements.ReplaceSkipRegex

            if ($Folder.ReplacementsGlobal -eq $true) {
                foreach ($Replace in $Replacements.BeforeSplit.Keys) {
                    if ($Replacements.ReplaceCaseInsenstive -and $Replacements.ReplaceSkipRegex) {
                        $MenuName = $MenuName -ireplace $Replace, $Replacements.BeforeSplit[$Replace]
                    } elseif ($Replacements.ReplaceCaseInsenstive) {
                        $MenuName = $MenuName -ireplace [regex]::Escape($Replace), $Replacements.BeforeSplit[$Replace]
                    } else {
                        $MenuName = $MenuName.Replace($Replace, $Replacements.BeforeSplit[$Replace])
                    }
                }
                $ResultsFile['MenuNameStep2AfterBeforeSplitReplacements'] = $MenuName
                if ($Replacements.SplitOn) {
                    $Splitted = $MenuName -split $Replacements.SplitOn
                    if ($null -ne $Replacements.AfterSplitPositionName) {
                        $PositionPlace = @(0)
                        $Name = ''
                        if ($Replacements.AfterSplitPositionName -is [System.Collections.IDictionary]) {
                            foreach ($FileNameToFind in $Replacements.AfterSplitPositionName.Keys) {
                                if ($MenuName -like $FileNameToFind) {
                                    [Array] $PositionPlace = $Replacements.AfterSplitPositionName[$FileNameToFind]
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
                        $ResultsFile['SplitPosition'] = $PositionPlace -join ', '
                        $ResultsFile['SplitPositionName'] = $Name
                    } else {
                        $Name = $Splitted[0]
                        $ResultsFile['SplitPosition'] = 0
                        $ResultsFile['SplitPositionName'] = $Name
                    }
                } else {
                    $Name = $MenuName
                    $ResultsFile['SplitPosition'] = $null
                    $ResultsFile['SplitPositionName'] = $Name
                }
                $ResultsFile['MenuNameStep3AfterSplittingPosition'] = $Name

                $formatStringToSentenceSplat = @{
                    Text               = $Name
                    RemoveCharsBefore  = $Replacements.BeforeRemoveChars
                    RemoveCharsAfter   = $Replacements.AfterRemoveChars
                    RemoveDoubleSpaces = $Replacements.AfterRemoveDoubleSpaces
                    MakeWordsUpperCase = $Replacements.AfterUpperChars
                    DisableAddingSpace = -not $Replacements.AddSpaceToName
                }
                $Name = Format-StringToSentence @formatStringToSentenceSplat

                $ResultsFile['BeforeRemoveChars'] = $Replacements.BeforeRemoveChars
                $ResultsFile['AfterRemoveChars'] = $Replacements.AfterRemoveChars
                $ResultsFile['AfterRemoveDoubleSpaces'] = $Replacements.AfterRemoveDoubleSpaces
                $ResultsFile['AfterUpperChars'] = $Replacements.AfterUpperChars
                $ResultsFile['AddSpaceToName'] = $Replacements.AddSpaceToName
                $ResultsFile['MenuNameStep4AfterFormat'] = $Name
                foreach ($Replace in $Replacements.AfterSplit.Keys) {
                    if ($Replacements.ReplaceCaseInsenstive -and $Replacements.ReplaceSkipRegex) {
                        $Name = $Name -ireplace $Replace, $Replacements.AfterSplit[$Replace]
                    } elseif ($Replacements.ReplaceCaseInsenstive) {
                        $Name = $Name -ireplace [regex]::Escape($Replace), $Replacements.AfterSplit[$Replace]
                    } else {
                        $Name = $Name.Replace($Replace, $Replacements.AfterSplit[$Replace])
                    }
                }
                $ResultsFile['MenuNameFinal'] = $Name

                $Type = 'global replacements'

                $ResultsFile['Type'] = $Type
                if ($DebugPreference) {
                    [PSCustomObject] $ResultsFile | Out-String | Write-Debug
                }

            } elseif ($Folder.Replacements) {
                foreach ($Replace in $Folder.Replacements.BeforeSplit.Keys) {
                    if ($Folder.Replacements.ReplaceCaseInsenstive -and $Folder.Replacements.ReplaceSkipRegex) {
                        $MenuName = $MenuName -ireplace $Replace, $Folder.Replacements.BeforeSplit[$Replace]
                    } elseif ($Folder.Replacements.ReplaceCaseInsenstive) {
                        $MenuName = $MenuName -ireplace [regex]::Escape($Replace), $Folder.Replacements.BeforeSplit[$Replace]
                    } else {
                        $MenuName = $MenuName.Replace($Replace, $Folder.Replacements.BeforeSplit[$Replace])
                    }
                }
                $ResultsFile['MenuNameStep2AfterBeforeSplitReplacements'] = $MenuName
                if ($Folder.Replacements.SplitOn) {
                    $Splitted = $MenuName -split $Folder.Replacements.SplitOn
                    if ($null -ne $Folder.Replacements.AfterSplitPositionName) {
                        $PositionPlace = @(0)
                        $Name = ''
                        if ($Folder.Replacements.AfterSplitPositionName -is [System.Collections.IDictionary]) {
                            foreach ($FileNameToFind in $Folder.Replacements.AfterSplitPositionName.Keys) {
                                if ($MenuName -like $FileNameToFind) {
                                    [Array] $PositionPlace = $Folder.Replacements.AfterSplitPositionName[$FileNameToFind]
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
                        $ResultsFile['SplitPosition'] = $PositionPlace -join ', '
                        $ResultsFile['SplitPositionName'] = $Name
                    } else {
                        $Name = $Splitted[0]
                        $ResultsFile['SplitPosition'] = 0
                        $ResultsFile['SplitPositionName'] = $Name
                    }
                } else {
                    $Name = $MenuName
                    $ResultsFile['SplitPosition'] = $null
                    $ResultsFile['SplitPositionName'] = $Name
                }

                $ResultsFile['MenuNameStep3AfterSplittingPosition'] = $Name

                $formatStringToSentenceSplat = @{
                    Text               = $Name
                    RemoveCharsBefore  = $Folder.Replacements.BeforeRemoveChars
                    RemoveCharsAfter   = $Folder.Replacements.AfterRemoveChars
                    RemoveDoubleSpaces = $Folder.Replacements.AfterRemoveDoubleSpaces
                    MakeWordsUpperCase = $Folder.Replacements.AfterUpperChars
                    DisableAddingSpace = -not $Folder.Replacements.AddSpaceToName
                }

                $Name = Format-StringToSentence @formatStringToSentenceSplat

                $ResultsFile['BeforeRemoveChars'] = $Folder.Replacements.BeforeRemoveChars
                $ResultsFile['AfterRemoveChars'] = $Folder.Replacements.AfterRemoveChars
                $ResultsFile['AfterRemoveDoubleSpaces'] = $Folder.Replacements.AfterRemoveDoubleSpaces
                $ResultsFile['AfterUpperChars'] = $Folder.Replacements.AfterUpperChars
                $ResultsFile['AddSpaceToName'] = $Folder.Replacements.AddSpaceToName
                $ResultsFile['MenuNameStep4AfterFormat'] = $Name

                foreach ($Replace in $Folder.Replacements.AfterSplit.Keys) {
                    if ($Folder.Replacements.ReplaceCaseInsenstive -and $Folder.Replacements.ReplaceSkipRegex) {
                        $Name = $Name -ireplace $Replace, $Folder.Replacements.AfterSplit[$Replace]
                    } elseif ($Folder.Replacements.ReplaceCaseInsenstive) {
                        $Name = $Name -ireplace [regex]::Escape($Replace), $Folder.Replacements.AfterSplit[$Replace]
                    } else {
                        $Name = $Name.Replace($Replace, $Folder.Replacements.AfterSplit[$Replace])
                    }
                }

                $ResultsFile['MenuNameFinal'] = $Name
                $Type = 'folder replacements'
                $ResultsFile['Type'] = $Type

                if ($DebugPreference) {
                    [PSCustomObject] $ResultsFile | Out-String | Write-Debug
                }

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
                    # Debug information for troubleshooting
                    Debug          = [PSCustomObject] $ResultsFile
                }
            } else {
                Write-Color -Text "[e]", "[TheDashboard] ", "Creating Menu ", "[error] ", "Couldn't create menu item for $($File.FullName). Problem with $Type" -Color Red, DarkGray, Red, DarkGray, Red
            }
        }
    }
}