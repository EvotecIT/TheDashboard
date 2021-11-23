function New-HTMLReport {
    [cmdletBinding()]
    param(
        $Logo,
        [System.Collections.IDictionary] $MenuBuilder,
        $Configuration,
        $Limits,
        $TopStats,
        [Array] $Files,
        [string] $HTMLPath,
        [switch] $ShowHTML
    )


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
                        $PageName = (( -join ($MenuBuilder[$Menu][$MenuReport].Name)).Replace(":", "_").Replace(" ", "_"))
                        New-NavLink -IconRegular calendar-check -Name $MenuBuilder[$Menu][$MenuReport].Name -Href "$PageName.html"
                    }
                }
            }
        } -MenuItemsWidth 250px

        # primary page data
        New-HTMLSectionStyle -BorderRadius 0px -HeaderBackGroundColor Grey -RemoveShadow
        New-HTMLPanelStyle -BorderRadius 0px
        New-HTMLSection -Invisible {
            New-HTMLPanel {
                #New-HTMLText -Text 'Users' -Color Red -Alignment center -FontSize 20px
                New-HTMLGage -Label 'All Users' -MinValue 0 -MaxValue $Limits.Users -Value $AllUsers.Count -Counter
                # New-HTMLText -Text 'Change since last + ', $DifferenceUsers -Color Red -Alignment right -FontSize 20px -SkipParagraph
            }
            New-HTMLPanel {
                #New-HTMLText -Text 'Groups' -Color Red -Alignment center -FontSize 20px
                New-HTMLGage -Label 'All Groups' -MinValue 0 -MaxValue $Limits.Groups -Value $AllGroups.Count -Counter
            }
            New-HTMLPanel {
                #New-HTMLText -Text 'Computers' -Color Red -Alignment center -FontSize 20px
                New-HTMLGage -Label 'All Computers' -MinValue 0 -MaxValue $Limits.Computers -Value $AllComputers.Count -Counter
            }
            New-HTMLPanel {
                #New-HTMLText -Text 'Users' -Color Red -Alignment center -FontSize 20px
                New-HTMLGage -Label 'All Group Policies' -MinValue 0 -MaxValue $Limits.GroupPolicies -Value $AllGroupPolicies.Count -Counter
            }
            <#
            New-HTMLPanel {
                New-HTMLText -Text 'Users ' -Alignment center -FontSize 20px -LineBreak
                New-HTMLText -Text $AllUsers.Count -Alignment center -FontSize 20px
            }
            New-HTMLPanel {
                New-HTMLText -Text 'Groups ' -Alignment center -FontSize 20px -LineBreak
                New-HTMLText -Text $Groups.Count -Alignment center -FontSize 20px
            }
            New-HTMLPanel {
                New-HTMLText -Text 'Computers ' -Alignment center -FontSize 20px -LineBreak
                New-HTMLText -Text $AllComputers.Count -Alignment center -FontSize 20px
            }
            New-HTMLPanel {
                New-HTMLText -Text 'Group Policies ' -Alignment center -FontSize 20px -LineBreak
                New-HTMLText -Text $GroupPolicies.Count -Alignment center -FontSize 20px
            }
            #>
        }
        New-HTMLSection -Invisible {
            New-HTMLPanel {
                $StatisticsKeys = $TopStats.Keys | Sort-Object | Select-Object -Last 10
                [Array] $Dates = foreach ($Day in $StatisticsKeys) {
                    $TopStats[$Day].Date
                }
                [Array] $LineComputers = foreach ($Day in $StatisticsKeys) {
                    $TopStats[$Day].Computers
                }
                [Array] $LineUsers = foreach ($Day in $StatisticsKeys) {
                    $TopStats[$Day].Users
                }
                [Array] $LineGroups = foreach ($Day in $StatisticsKeys) {
                    $TopStats[$Day].Groups
                }
                [Array] $LineGroupPolicies = foreach ($Day in $StatisticsKeys) {
                    $TopStats[$Day].'Group Policies'
                }

                New-HTMLChart -Title 'Domain Summary' -TitleAlignment center {
                    New-ChartAxisX -Type datetime -Names $Dates
                    New-ChartAxisY -TitleText 'Numbers' -Show
                    New-ChartLine -Name 'Computers' -Value $LineComputers
                    New-ChartLine -Name 'Users' -Value $LineUsers
                    New-ChartLine -Name 'Groups' -Value $LineGroups
                    New-ChartLine -Name 'Group Policies' -Value $LineGroupPolicies
                }

                <#
                New-HTMLChart -Title 'Domain Summary' -TitleAlignment center {
                    New-ChartAxisX -Type datetime -Names $Dates
                    New-ChartAxisY -TitleText 'Numbers' -Show
                    New-ChartLine -Name 'Computers' -Value $LineComputers
                    #New-ChartLine -Name 'Users' -Value $LineUsers
                    #New-ChartLine -Name 'Groups' -Value $LineGroups
                    #New-ChartLine -Name 'Group Policies' -Value $LineGroupPolicies
                } -Group 'LinkedCharts1' -Height 250
                New-HTMLChart -Title 'Domain Summary' -TitleAlignment center {
                    New-ChartAxisX -Type datetime -Names $Dates
                    New-ChartAxisY -TitleText 'Numbers' -Show
                    #New-ChartLine -Name 'Computers' -Value $LineComputers
                    New-ChartLine -Name 'Users' -Value $LineUsers
                    #New-ChartLine -Name 'Groups' -Value $LineGroups
                    #New-ChartLine -Name 'Group Policies' -Value $LineGroupPolicies
                } -Group 'LinkedCharts1' -Height 250
                New-HTMLChart -Title 'Domain Summary' -TitleAlignment center {
                    New-ChartAxisX -Type datetime -Names $Dates
                    New-ChartAxisY -TitleText 'Numbers' -Show
                    #New-ChartLine -Name 'Computers' -Value $LineComputers
                    #New-ChartLine -Name 'Users' -Value $LineUsers
                    New-ChartLine -Name 'Groups' -Value $LineGroups
                    #New-ChartLine -Name 'Group Policies' -Value $LineGroupPolicies
                } -Group 'LinkedCharts1' -Height 250
                New-HTMLChart -Title 'Domain Summary' -TitleAlignment center {
                    New-ChartAxisX -Type datetime -Names $Dates
                    New-ChartAxisY -TitleText 'Numbers' -Show
                    #New-ChartLine -Name 'Computers' -Value $LineComputers
                    #New-ChartLine -Name 'Users' -Value $LineUsers
                    #New-ChartLine -Name 'Groups' -Value $LineGroups
                    New-ChartLine -Name 'Group Policies' -Value $LineGroupPolicies
                } -Group 'LinkedCharts1' -Height 250
                #>
            }
            New-HTMLPanel {
                New-HTMLCalendar {
                    foreach ($CalendarEntry in $Files) {
                        # The check make sure that report doesn't run over midnight when using +30 minutes. If it runs over midnight it looks bad as it spans over 2 days
                        # we then remove 30 minutes instead to prevent this
                        if ($($CalendarEntry.Date).Day -eq $($($CalendarEntry.Date).AddMinutes(30)).Day) {
                            New-CalendarEvent -Title $CalendarEntry.Name -StartDate $CalendarEntry.Date -EndDate $($CalendarEntry.Date).AddMinutes(30) -Url $CalendarEntry.Href
                        } else {
                            New-CalendarEvent -Title $CalendarEntry.Name -StartDate $CalendarEntry.Date.AddMinutes(-30) -EndDate $($CalendarEntry.Date) -Url $CalendarEntry.Href
                        }
                    }
                }
            }
        }
        <#
        foreach ($Report in $Type) {
            if ($Report -eq 'ServiceAccounts') {
                New-HTMLPage -Name 'ServiceAccounts' {
                    $ReportOutput = Get-ReportServiceAccounts -AllUsers $AllUsers -Cache $Cache
                    #if ($AttachExcel) {
                    #    $ReportPathExcel = "$ExcelPath\ServiceAccounts\ServiceAccounts.xlsx"
                    #    Export-ADReportToExcel -ReportPathExcel $ReportPathExcel -Objects $Users -Summary $Summary -SummaryTitle 'Service Accounts' -ExportSummary
                    #}
                    Invoke-Report -Summary $ReportOutput.Summary -Title 'Service Accounts' -Statistics $ReportOutput.Statistics -Users $ReportOutput.Objects
                }
            } elseif ($Report -eq 'UsersPasswordNeverExpire') {
                New-HTMLPage -Name 'UsersPNE' {
                    $ReportOutput = Get-ReportPasswordNeverExpire -AllUsers $AllUsers -Cache $Cache
                    Invoke-Report -Summary $ReportOutput.Summary -Title 'Users with Password Never Expires' -Statistics $ReportOutput.Statistics -Users $ReportOutput.Objects
                }
            } elseif ($Report -eq 'ComputersLimitedINS') {
                New-HTMLPage -Name 'ComputersINS' {
                    $ReportOutput = Get-ReportComputerINS -AllComputers $AllComputers -Cache $Cache
                    Invoke-Report -Summary $ReportOutput.Summary -Title 'Computers in INS' -Statistics $ReportOutput.Statistics -Users $ReportOutput.Objects
                }
            }
        }
        #>
        foreach ($Menu in $MenuBuilder.Keys) {
            $TopMenuSplat = @{
                Name = $Menu
            }
            if ($Configuration.Folders.$Menu.IconType) {
                $TopMenuSplat[$Configuration.Folders.$Menu.IconType] = $Configuration.Folders.$Menu.Icon
            }

            foreach ($MenuReport in $MenuBuilder[$Menu].Keys) {
                $PathToSubReports = [io.path]::GetDirectoryName($HTMLPath)
                #$PageName = ( -join ($MenuBuilder[$Menu][$MenuReport].Name, " ", $MenuBuilder[$Menu][$MenuReport].Date)).Replace(":", "_").Replace(" ", "_")
                $PageName = ($MenuBuilder[$Menu][$MenuReport].Name).Replace(":", "_").Replace(" ", "_")
                $FullPath = [io.path]::Combine($PathToSubReports, "$PageName.html")
                New-HTMLPage -Name $MenuBuilder[$Menu][$MenuReport].Name {
                    New-HTMLFrame -SourcePath $MenuBuilder[$Menu][$MenuReport].Href -Scrolling Auto -Height 1500px
                } -FilePath $FullPath
            }

        }
    } -FilePath $HTMLPath -Online -ShowHTML:$ShowHTML.IsPresent -TitleText 'AD Compliance Dashboard'
}