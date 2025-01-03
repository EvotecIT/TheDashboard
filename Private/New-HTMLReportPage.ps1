function New-HTMLReportPage {
    [cmdletBinding()]
    param(
        [PSCustomObject] $Report,
        [Array] $AllReports,
        [Array] $HistoryReports,
        [string] $FilePath,
        [string] $PathToSubReports,
        [string] $Name,
        [switch] $SubReport
    )
    if ($SubReport) {
        Write-Color -Text '[i]', '[HTML ] ', "Generating HTML page ($MenuReport) sub report ($FilePath)" -Color Yellow, DarkGray, Yellow
    } else {
        Write-Color -Text '[i]', '[HTML ] ', "Generating HTML page ($MenuReport) report ($FilePath)" -Color Yellow, DarkGray, Yellow
    }
    New-HTMLPage -Name $Name -Title "The Dashboard - $Name" {
        New-HTMLSection -HeaderText "Summary for $($Report.Name)" -HeaderBackGroundColor Black {
            New-HTMLSection -Invisible {
                New-HTMLPanel {
                    New-HTMLText -Text "Report name: ", $CurrentReport.Name -FontSize 12px
                    New-HTMLText -Text "Report date: ", $CurrentReport.Date -FontSize 12px

                    New-HTMLText -Text "All reports in this catagory: ", $AllReports.Count -FontSize 12px
                    New-HTMLList {
                        if ($AllReports.Count -eq 1) {
                            New-HTMLListItem -Text "Date in report: ", $AllReports[0].Date -FontSize 12px -FontWeight normal, bold -TextDecoration none, underline
                        } else {
                            New-HTMLListItem -Text "Date ranges from: ", $AllReports[$AllReports.Count - 1].Date, " to ", $AllReports[0].Date -FontSize 12px -FontWeight normal, bold, normal, bold -TextDecoration none, underline, none, underline
                        }
                    }
                    if ($HistoryReports.Count) {
                        New-HTMLText -Text "History reports in this catagory: ", $HistoryReports.Count -FontSize 12px
                        New-HTMLList {
                            if ($HistoryReports.Count -gt 1) {
                                New-HTMLListItem -Text "Date ranges from: ", $HistoryReports[$AllReports.Count - 1].Date, " to ", $HistoryReports[0].Date -FontSize 12px -FontWeight normal, bold, normal, bold -TextDecoration none, underline, none, underline
                            } else {
                                New-HTMLListItem -Text "Date in report: ", $HistoryReports[0].Date -FontSize 12px -FontWeight normal, bold -TextDecoration none, underline
                            }
                        }
                    }
                } -Invisible
            }
            New-HTMLSection -Invisible {
                New-HTMLCalendar {
                    foreach ($CalendarEntry in $AllReports) {
                        # The check make sure that report doesn't run over midnight when using +30 minutes. If it runs over midnight it looks bad as it spans over 2 days
                        # we then remove 30 minutes instead to prevent this
                        if ($($CalendarEntry.Date).Day -eq $($($CalendarEntry.Date).AddMinutes(30)).Day) {
                            New-CalendarEvent -Title $CalendarEntry.Name -StartDate $CalendarEntry.Date -EndDate $($CalendarEntry.Date).AddMinutes(30) -Url $CalendarEntry.FileName
                        } else {
                            New-CalendarEvent -Title $CalendarEntry.Name -StartDate $CalendarEntry.Date.AddMinutes(-30) -EndDate $($CalendarEntry.Date) -Url $CalendarEntry.FileName
                        }
                    }
                    # if there are history reports we add them, but we do it as part of iframe without creating new files
                    # this means it's much faster to generate, as we generate only X amount of reports, and rest will be inline
                    # the drawback is - there is no seprate link for those, so copying link will not work
                    foreach ($CalendarEntry in $HistoryReports) {
                        # The check make sure that report doesn't run over midnight when using +30 minutes. If it runs over midnight it looks bad as it spans over 2 days
                        # we then remove 30 minutes instead to prevent this
                        if ($($CalendarEntry.Date).Day -eq $($($CalendarEntry.Date).AddMinutes(30)).Day) {
                            New-CalendarEvent -Title $CalendarEntry.Name -StartDate $CalendarEntry.Date -EndDate $($CalendarEntry.Date).AddMinutes(30) -Url $CalendarEntry.Href -TargetName 'iFrameWithContent'
                        } else {
                            New-CalendarEvent -Title $CalendarEntry.Name -StartDate $CalendarEntry.Date.AddMinutes(-30) -EndDate $($CalendarEntry.Date) -Url $CalendarEntry.Href -TargetName 'iFrameWithContent'
                        }
                    }
                } -HeaderRight @('dayGridMonth', 'timeGridWeek', 'timeGridDay', 'listMonth', 'listYear')
            }
        } -Height 300px
        New-HTMLSection -Invisible {

        } -Height 15px
        New-HTMLFrame -SourcePath $Report.Href -Scrolling Auto -Height 2000px -Name 'iFrameWithContent'
    } -FilePath $FilePath
}