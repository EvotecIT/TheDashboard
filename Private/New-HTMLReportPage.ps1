function New-HTMLReportPage {
    [cmdletBinding()]
    param(
        [System.Collections.IDictionary] $Report,
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
    New-HTMLPage -Name $Name {
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
                            New-HTMLListItem -Text "Date ranges from: ", $AllReports[0].Date, " to ", $AllReports[$AllReports.Count - 1].Date -FontSize 12px -FontWeight normal, bold, normal, bold -TextDecoration none, underline, none, underline
                        }
                    }
                    if ($HistoryReports.Count) {
                        New-HTMLText -Text "History reports in this catagory: ", $HistoryReports.Count -FontSize 12px
                        New-HTMLList {
                            if ($HistoryReports.Count -gt 1) {
                                New-HTMLListItem -Text "Date ranges from: ", $HistoryReports[0].Date, " to ", $HistoryReports[$AllReports.Count - 1].Date -FontSize 12px -FontWeight normal, bold, normal, bold -TextDecoration none, underline, none, underline
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
                        #$FullPathOther = [io.path]::Combine($PathToSubReports, $CalendarEntry.FileName)
                        if ($($CalendarEntry.Date).Day -eq $($($CalendarEntry.Date).AddMinutes(30)).Day) {
                            New-CalendarEvent -Title $CalendarEntry.Name -StartDate $CalendarEntry.Date -EndDate $($CalendarEntry.Date).AddMinutes(30) -Url $CalendarEntry.FileName
                        } else {
                            New-CalendarEvent -Title $CalendarEntry.Name -StartDate $CalendarEntry.Date.AddMinutes(-30) -EndDate $($CalendarEntry.Date) -Url $CalendarEntry.FileName
                        }
                    }
                } -HeaderRight @('dayGridMonth', 'timeGridWeek', 'timeGridDay', 'listMonth', 'listYear')
            }
        } -Height 300px
        New-HTMLSection -Invisible {

        } -Height 15px
        New-HTMLFrame -SourcePath $Report.Href -Scrolling Auto -Height 2000px
    } -FilePath $FilePath
}