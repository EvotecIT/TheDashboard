function New-HTMLReport {
    [cmdletBinding()]
    param(
        [Array] $OutputElements,
        [string] $Logo,
        [System.Collections.IDictionary] $MenuBuilder,
        [System.Collections.IDictionary] $Configuration,
        [System.Collections.IDictionary] $TopStats,
        [Array] $Files,
        [string] $HTMLPath,
        [switch] $ShowHTML,
        [switch] $Online
    )
    $TimeLogHTML = Start-TimeLog
    Write-Color -Text '[i]', '[HTML ] ', "Generating HTML report ($HTMLPath)" -Color Yellow, DarkGray, Yellow
    # Build report
    New-HTML {
        New-HTMLNavTop -HomeLinkHome -Logo $Logo {
            foreach ($Menu in $MenuBuilder.Keys) {
                $TopMenuSplat = @{
                    Name = $Menu
                }
                if ($Configuration.Folders.$Menu.IconType) {
                    $TopMenuSplat[$Configuration.Folders.$Menu.IconType] = $Configuration.Folders.$Menu.Icon
                }
                New-NavTopMenu @TopMenuSplat {
                    foreach ($MenuReport in $MenuBuilder[$Menu].Keys) {
                        #$PageName = (( -join ($MenuBuilder[$Menu][$MenuReport].Name, " ", $MenuBuilder[$Menu][$MenuReport].Date)).Replace(":", "_").Replace(" ", "_"))
                        $PageName = (( -join ($MenuBuilder[$Menu][$MenuReport]['Current'].Name)).Replace(":", "_").Replace(" ", "_"))
                        New-NavLink -IconRegular calendar-check -Name $MenuBuilder[$Menu][$MenuReport]['Current'].Name -Href "$PageName.html"
                    }
                }
            }
        } -MenuItemsWidth 250px

        # primary page data
        New-HTMLSectionStyle -BorderRadius 0px -HeaderBackGroundColor Grey -RemoveShadow
        New-HTMLPanelStyle -BorderRadius 0px

        New-HTMLSection -Invisible {
            foreach ($E in $OutputElements) {
                New-HTMLPanel {
                    #New-HTMLText -Text 'Users' -Color Red -Alignment center -FontSize 20px
                    New-HTMLGage -Label $E.Label -MinValue $E.MinValue -MaxValue $E.MaxValue -Value $E.Value -Counter
                    $TopStats[$E.Date][$($E.Label)] = $E.Value
                    # New-HTMLText -Text 'Change since last + ', $DifferenceUsers -Color Red -Alignment right -FontSize 20px -SkipParagraph
                }
            }
        }
        New-HTMLSection -Invisible {
            New-HTMLPanel {
                $StatisticsKeys = $TopStats.Keys | Sort-Object | Select-Object -Last 50
                [Array] $Dates = foreach ($Day in $StatisticsKeys) {
                    $TopStats[$Day].Date
                }

                foreach ($UserInput in $Dates) {
                    $TopStats[$Day].$($UserInput.Label) = $UserInput.Value
                }
                New-HTMLChart -Title 'Domain Summary' -TitleAlignment center {
                    New-ChartAxisX -Type datetime -Names $Dates
                    New-ChartAxisY -TitleText 'Numbers' -Show

                    foreach ($UserInput in $OutputElements) {
                        $Values = foreach ($Day in $StatisticsKeys) {
                            $TopStats[$Day].$($UserInput.Label)
                        }
                        New-ChartLine -Name $UserInput.Label -Value $Values
                    }
                }
            }
            New-HTMLPanel {
                New-HTMLCalendar {
                    foreach ($CalendarEntry in $Files) {
                        # The check make sure that report doesn't run over midnight when using +30 minutes. If it runs over midnight it looks bad as it spans over 2 days
                        # we then remove 30 minutes instead to prevent this
                        if ($($CalendarEntry.Date).Day -eq $($($CalendarEntry.Date).AddMinutes(30)).Day) {
                            New-CalendarEvent -Title $CalendarEntry.Name -StartDate $CalendarEntry.Date -EndDate $($CalendarEntry.Date).AddMinutes(30) -Url $CalendarEntry.FileName
                        } else {
                            New-CalendarEvent -Title $CalendarEntry.Name -StartDate $CalendarEntry.Date.AddMinutes(-30) -EndDate $($CalendarEntry.Date) -Url $CalendarEntry.FileName
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

            foreach ($MenuReport in $MenuBuilder[$Menu].Keys) {

                $PathToSubReports = [io.path]::GetDirectoryName($HTMLPath)
                #$PageName = ( -join ($MenuBuilder[$Menu][$MenuReport].Name, " ", $MenuBuilder[$Menu][$MenuReport].Date)).Replace(":", "_").Replace(" ", "_")
                $PageName = ($MenuBuilder[$Menu][$MenuReport]['Current'].Name).Replace(":", "_").Replace(" ", "_")
                $FullPath = [io.path]::Combine($PathToSubReports, "$PageName.html")

                $CurrentReport = $MenuBuilder[$Menu][$MenuReport]['Current']
                $AllReports = $MenuBuilder[$Menu][$MenuReport]['All']

                $Name = $CurrentReport.Name
                New-HTMLReportPage -Report $CurrentReport -AllReports $AllReports -FilePath $FullPath -PathToSubReports $PathToSubReports -Name $Name

                foreach ($Report in $AllReports) {
                    if ($Report.Name -eq $CurrentReport.Name -and $Report.Date -eq $CurrentReport.Date) {
                        #continue
                    }
                    $FullPathOther = [io.path]::Combine($PathToSubReports, $Report.FileName)
                    $Name = $Report.Name + ' - ' + $Report.Date
                    New-HTMLReportPage -Report $Report -AllReports $AllReports -FilePath $FullPathOther -PathToSubReports $PathToSubReports -Name $Name
                }
            }
            Write-Color -Text '[i]', '[HTML ] ', "Ending Menu for ", $Menu -Color Yellow, DarkGray, Yellow, DarkCyan
        }
        Write-Color -Text '[i]', '[HTML ] ', "Saving HTML reports (this may take a while...)" -Color Yellow, DarkGray, Yellow
    } -FilePath $HTMLPath -ShowHTML:$ShowHTML.IsPresent -TitleText 'The Dashboard' -Online:$Online.IsPresent

    $TimeLogEndHTML = Stop-TimeLog -Time $TimeLogHTML -Option OneLiner
    Write-Color -Text '[i]', '[HTML ] ', 'Generating HTML report', " [Time to execute: $TimeLogEndHTML]" -Color Yellow, DarkGray, Yellow, DarkGray
}