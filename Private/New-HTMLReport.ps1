﻿function New-HTMLReport {
    [cmdletBinding()]
    param(
        [Array] $OutputElements,
        [string] $Logo,
        [string] $Extension,
        [System.Collections.IDictionary] $MenuBuilder,
        [System.Collections.IDictionary] $Configuration,
        [System.Collections.IDictionary] $ExportData,
        [Array] $Files,
        [string] $HTMLPath,
        [switch] $ShowHTML,
        [switch] $Online,
        [Uri] $UrlPath,
        [switch] $Force,
        [switch] $Pretend
    )
    $TimeLogHTML = Start-TimeLog
    Write-Color -Text '[i]', '[HTML ] ', "Generating HTML report ($HTMLPath)" -Color Yellow, DarkGray, Yellow

    $FilePathsGenerated = [System.Collections.Generic.List[string]]::new()
    $FilePathsGenerated.Add($HTMLPath) # return filepath for main report

    if ($Pretend) {
        foreach ($Menu in $MenuBuilder.Keys) {
            Write-Color -Text '[i]', '[HTML ] ', "Building Menu for ", $Menu -Color Yellow, DarkGray, Yellow, DarkCyan
            $TopMenuSplat = @{
                Name = $Menu
            }
            if ($Configuration.Folders.$Menu.IconType) {
                $TopMenuSplat[$Configuration.Folders.$Menu.IconType] = $Configuration.Folders.$Menu.Icon
            }

            foreach ($MenuReport in $MenuBuilder[$Menu].Keys | Sort-Object) {
                $MenuLink = $MenuBuilder[$Menu][$MenuReport]['Current'].MenuLink
                $PathToSubReports = [io.path]::GetDirectoryName($HTMLPath)
                $PageName = ($MenuBuilder[$Menu][$MenuReport]['Current'].Name).Replace(":", "_").Replace(" ", "_")
                $FullPath = [io.path]::Combine($PathToSubReports, "$($MenuLink)_$PageName$($Extension)")

                $CurrentReport = $MenuBuilder[$Menu][$MenuReport]['Current']
                [Array] $FullReports = $MenuBuilder[$Menu][$MenuReport]['Full']
                [Array] $HistoryReports = $MenuBuilder[$Menu][$MenuReport]['History']

                $Name = $CurrentReport.Name
                $FilePathsGenerated.Add($FullPath)  # return filepath for main report

                foreach ($Report in $FullReports) {
                    $FullPathOther = [io.path]::Combine($PathToSubReports, $Report.FileName)
                    $Name = $Report.Name + ' - ' + $Report.Date
                    $FilePathsGenerated.Add($FullPathOther) # return filepath for other reports
                }
            }
            Write-Color -Text '[i]', '[HTML ] ', "Ending Menu for ", $Menu -Color Yellow, DarkGray, Yellow, DarkCyan
        }
    } else {
        # Build report
        New-HTML {
            $newHTMLNavTopSplat = @{
                Logo            = $Logo
                MenuItemsWidth  = '250px'
                NavigationLinks = {
                    foreach ($Menu in $MenuBuilder.Keys) {
                        $TopMenuSplat = @{
                            Name = $Menu
                        }
                        if ($Configuration.Folders.$Menu.IconType) {
                            $TopMenuSplat[$Configuration.Folders.$Menu.IconType] = $Configuration.Folders.$Menu.Icon
                        }
                        New-NavTopMenu @TopMenuSplat {
                            foreach ($MenuReport in $MenuBuilder[$Menu].Keys | Sort-Object) {
                                $MenuLink = $MenuBuilder[$Menu][$MenuReport]['Current'].MenuLink
                                $PageName = (( -join ($MenuBuilder[$Menu][$MenuReport]['Current'].Name)).Replace(":", "_").Replace(" ", "_"))
                                if ($UrlPath) {
                                    New-NavLink -IconRegular calendar-check -Name $MenuBuilder[$Menu][$MenuReport]['Current'].Name -Href "$UrlPath/$($MenuLink)_$($PageName)$($Extension)"
                                } else {
                                    New-NavLink -IconRegular calendar-check -Name $MenuBuilder[$Menu][$MenuReport]['Current'].Name -Href "$($MenuLink)_$($PageName)$($Extension)"
                                }
                            }
                        }
                    }
                }
            }
            if ($UrlPath) {
                $FileNameHome = [System.IO.Path]::GetFileName($HTMLPath)
                $newHTMLNavTopSplat['HomeLink'] = "$UrlPath/$FileNameHome"
            } else {
                $newHTMLNavTopSplat['HomeLinkHome'] = $true
            }
            New-HTMLNavTop @newHTMLNavTopSplat

            # primary page data
            New-HTMLSectionStyle -BorderRadius 0px -HeaderBackGroundColor Grey -RemoveShadow
            New-HTMLPanelStyle -BorderRadius 0px

            New-HTMLSection -Invisible {
                foreach ($E in $OutputElements) {
                    New-HTMLPanel {
                        New-HTMLGage -Label $E.Label -MinValue $E.MinValue -MaxValue $E.MaxValue -Value $E.Value -Counter
                        $ExportData['Statistics'][$E.Date][$($E.Label)] = $E.Value
                        # New-HTMLText -Text 'Change since last + ', $DifferenceUsers -Color Red -Alignment right -FontSize 20px -SkipParagraph
                    }
                }
            }
            New-HTMLSection -Invisible {
                New-HTMLPanel {
                    $StatisticsKeys = $ExportData['Statistics'].Keys | Sort-Object | Select-Object -Last 50
                    [Array] $Dates = foreach ($Day in $StatisticsKeys) {
                        $ExportData['Statistics'][$Day].Date
                    }

                    foreach ($UserInput in $Dates) {
                        $ExportData['Statistics'][$Day].$($UserInput.Label) = $UserInput.Value
                    }
                    New-HTMLChart -Title 'Domain Summary' -TitleAlignment center {
                        New-ChartAxisX -Type datetime -Names $Dates
                        New-ChartAxisY -TitleText 'Numbers' -Show

                        foreach ($UserInput in $OutputElements) {
                            $Values = foreach ($Day in $StatisticsKeys) {
                                $ExportData['Statistics'][$Day].$($UserInput.Label)
                            }
                            New-ChartLine -Name $UserInput.Label -Value $Values
                        }
                    }
                }
                New-HTMLPanel {
                    New-HTMLCalendar {
                        foreach ($Menu in $MenuBuilder.Keys) {
                            foreach ($MenuReport in $MenuBuilder[$Menu].Keys) {
                                [Array] $FullReports = $MenuBuilder[$Menu][$MenuReport]['Full']
                                foreach ($CalendarEntry in $FullReports) {
                                    # The check make sure that report doesn't run over midnight when using +30 minutes. If it runs over midnight it looks bad as it spans over 2 days
                                    # we then remove 30 minutes instead to prevent this
                                    if ($CalendarEntry.Include) {
                                        if ($($CalendarEntry.Date).Day -eq $($($CalendarEntry.Date).AddMinutes(30)).Day) {
                                            New-CalendarEvent -Title $CalendarEntry.Name -StartDate $CalendarEntry.Date -EndDate $($CalendarEntry.Date).AddMinutes(30) -Url $CalendarEntry.FileName
                                        } else {
                                            New-CalendarEvent -Title $CalendarEntry.Name -StartDate $CalendarEntry.Date.AddMinutes(-30) -EndDate $($CalendarEntry.Date) -Url $CalendarEntry.FileName
                                        }
                                    }
                                }
                                # We don't add history reports to calendar as history reports are only shown in iframe with current report
                            }
                        }
                    } -HeaderRight @('dayGridMonth', 'timeGridWeek', 'timeGridDay', 'listMonth', 'listYear')
                }
            }
            foreach ($Menu in $MenuBuilder.Keys) {
                Write-Color -Text '[i]', '[HTML ] ', "Building Menu for ", $Menu -Color Yellow, DarkGray, Yellow, DarkCyan
                $TopMenuSplat = @{
                    Name = $Menu
                }
                if ($Configuration.Folders.$Menu.IconType) {
                    $TopMenuSplat[$Configuration.Folders.$Menu.IconType] = $Configuration.Folders.$Menu.Icon
                }

                foreach ($MenuReport in $MenuBuilder[$Menu].Keys | Sort-Object) {
                    $MenuLink = $MenuBuilder[$Menu][$MenuReport]['Current'].MenuLink
                    $PathToSubReports = [io.path]::GetDirectoryName($HTMLPath)
                    $PageName = ($MenuBuilder[$Menu][$MenuReport]['Current'].Name).Replace(":", "_").Replace(" ", "_")
                    $FullPath = [io.path]::Combine($PathToSubReports, "$($MenuLink)_$PageName$($Extension)")

                    $CurrentReport = $MenuBuilder[$Menu][$MenuReport]['Current']
                    [Array] $FullReports = $MenuBuilder[$Menu][$MenuReport]['Full']
                    [Array] $HistoryReports = $MenuBuilder[$Menu][$MenuReport]['History']

                    $Name = $CurrentReport.Name
                    if (-not $CurrentReport.SkipGeneration) {
                        New-HTMLReportPage -Report $CurrentReport -FullReports $FullReports -HistoryReports $HistoryReports -FilePath $FullPath -PathToSubReports $PathToSubReports -Name $Name
                    } else {
                        Write-Color -Text '[i]', '[HTML ] ', "Skipping generation of ", $FullPath, ". generation not required..." -Color Yellow, DarkGray, Yellow
                    }
                    $FilePathsGenerated.Add($FullPath)  # return filepath for main report

                    foreach ($Report in $FullReports) {
                        if ($Report.Include) {
                            $FullPathOther = [io.path]::Combine($PathToSubReports, $Report.FileName)
                            $Name = $Report.Name + ' - ' + $Report.Date
                            $FilePathsGenerated.Add($FullPathOther) # return filepath for other reports
                            if (-not $Report.SkipGeneration) {
                                New-HTMLReportPage -SubReport -Report $Report -FullReports $FullReports -FilePath $FullPathOther -PathToSubReports $PathToSubReports -Name $Name -HistoryReports $HistoryReports
                            } else {
                                Write-Color -Text '[i]', '[HTML ] ', "Skipping generation of ", $FullPathOther, ". generation not required..." -Color Yellow, DarkGray, Yellow
                            }
                        }
                    }
                }
                Write-Color -Text '[i]', '[HTML ] ', "Ending Menu for ", $Menu -Color Yellow, DarkGray, Yellow, DarkCyan
            }
            Write-Color -Text '[i]', '[HTML ] ', "Saving HTML reports (this may take a while...)" -Color Yellow, DarkGray, Yellow
        } -FilePath $HTMLPath -ShowHTML:$ShowHTML.IsPresent -TitleText 'The Dashboard' -Online:$Online.IsPresent -Author "Przemyslaw Klys @ Evotec"
    }
    $TimeLogEndHTML = Stop-TimeLog -Time $TimeLogHTML -Option OneLiner
    Write-Color -Text '[i]', '[HTML ] ', 'Generating HTML report', " [Time to execute: $TimeLogEndHTML]" -Color Yellow, DarkGray, Yellow, DarkGray
    # lets return files paths we generated
    $FilePathsGenerated
}