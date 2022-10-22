function New-HTMLReportPage {
    [cmdletBinding()]
    param(
        [System.Collections.IDictionary] $Report,
        [Array] $AllReports,
        [string] $FilePath,
        [string] $PathToSubReports
    )
    #$TimeLogPageHTML = Start-TimeLog

    Write-Color -Text '[i]', '[HTML ] ', "Generating HTML page ($MenuReport) report ($FilePath)" -Color Yellow, DarkGray, Yellow

    $Name = $Report.Name + ' - ' + $Report.Date
    New-HTMLPage -Name $Name {
        New-HTMLSection -HeaderText "Summary for $($Report.Name)" -HeaderBackGroundColor Black {
            New-HTMLSection -Invisible {
                New-HTMLPanel {
                    New-HTMLText -Text "Report name: ", $CurrentReport.Name -FontSize 12px
                    New-HTMLText -Text "Report date: ", $CurrentReport.Date -FontSize 12px

                    New-HTMLText -Text "All reports in this catagory: ", $AllReports.Count -FontSize 12px
                    New-HTMLList {
                        New-HTMLListItem -Text "Date ranges from: ", $AllReports[0].Date, " to ", $AllReports[$AllReports.Count - 1].Date -FontSize 12px -FontWeight normal, bold, normal, bold -TextDecoration none, underline, none, underline
                    }
                } -Invisible
            }
            New-HTMLSection -Invisible {
                New-HTMLCalendar {
                    foreach ($CalendarEntry in $AllReports) {
                        # The check make sure that report doesn't run over midnight when using +30 minutes. If it runs over midnight it looks bad as it spans over 2 days
                        # we then remove 30 minutes instead to prevent this
                        $FullPathOther = [io.path]::Combine($PathToSubReports, $CalendarEntry.FileName)
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

    #$TimeLogPageEndHTML = Stop-TimeLog -Time $TimeLogPageHTML -Option OneLiner
    #Write-Color -Text '[i]', '[HTML ] ', "Generating HTML page ($MenuReport) report", " [Time to execute: $TimeLogPageEndHTML]" -Color Yellow, DarkGray, Yellow, DarkGray
}