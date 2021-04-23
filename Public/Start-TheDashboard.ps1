function Start-TheDashboard {
    [cmdletBinding()]
    param(
        [string] $HTMLPath,
        [string] $ExcelPath,
        [string] $StatisticsPath,
        [parameter(Mandatory)][ValidateSet('ServiceAccounts', 'UsersPasswordNeverExpire', 'ComputersLimitedINS')][string[]] $Type,
        [string] $Logo,
        [System.Collections.IDictionary] $Limits,
        [System.Collections.IDictionary] $Folders,
        [System.Collections.IDictionary] $Replacements,
        [switch] $ShowHTML
    )
    $TopStats = [ordered] @{}
    $Cache = @{}
    $Properties = 'DistinguishedName', 'mail', 'LastLogonDate', 'PasswordLastSet', 'DisplayName', 'Manager', 'Description', 'PasswordNeverExpires', 'PasswordNotRequired', 'PasswordExpired', 'UserPrincipalName', 'SamAccountName', 'CannotChangePassword', 'TrustedForDelegation', 'TrustedToAuthForDelegation'
    $AllUsers = Get-ADUser -Filter * -Properties $Properties
    $PropertiesComputer = 'DistinguishedName', 'LastLogonDate', 'PasswordLastSet', 'Enabled', 'DnsHostName', 'PasswordNeverExpires', 'PasswordNotRequired', 'PasswordExpired', 'Manager', 'OperatingSystemVersion', 'OperatingSystem' , 'TrustedForDelegation'
    $AllComputers = Get-ADComputer -Filter * -Properties $PropertiesComputer
    $AllGroups = Get-ADGroup -Filter *
    $AllGroupPolicies = Get-GPO -All

    $ComputerEnabled = 0
    $ComputerDisabled = 0
    $UserDisabled = 0
    $UserEnabled = 0
    foreach ($Computer in $AllComputers) {
        if ($Computer.Enabled) {
            $ComputerEnabled++
        } else {
            $ComputerDisabled++
        }
    }
    foreach ($Computer in $AllUsers) {
        if ($User.Disabled) {
            $UserEnabled++
        } else {
            $UserDisabled++
        }
    }


    foreach ($U in $AllUsers) {
        $Cache[$U.DistinguishedName] = $U
    }
    foreach ($C in $AllComputers) {
        $Cache[$C.DistinguishedName] = $C
    }

    if ($StatisticsPath -and (Test-Path -LiteralPath $StatisticsPath)) {
        $TopStats = Import-Clixml -LiteralPath $StatisticsPath
    }
    $TodayString = Get-Date
    $TopStats[$TodayString] = [ordered] @{}
    $TopStats[$TodayString]['Date'] = Get-Date
    $TopStats[$TodayString]['Computers'] = $AllComputers.Count
    $TopStats[$TodayString]['Users'] = $AllUsers.Count
    $TopStats[$TodayString]['Groups'] = $AllGroups.Count
    $TopStats[$TodayString]['Group Policies'] = $AllGroupPolicies.Count


    # create menu information based on files
    $Files = foreach ($Folder in $Folders.Keys) {
        $FilesInFolder = Get-ChildItem -LiteralPath $Folders[$Folder].Path -ErrorAction SilentlyContinue
        foreach ($File in $FilesInFolder) {
            $Href = "$($Folders[$Folder].Url)/$($File.Name)"

            $MenuName = $File.BaseName
            foreach ($Replace in $Replacements.BeforeSplit.Keys) {
                $MenuName = $MenuName.Replace($Replace, $Configuration.Replacements.BeforeSplit[$Replace])
            }
            #$Splitted = ($File.BaseName.Replace('Testimo', '').Replace('GPOZaurr', '').Replace('GroupMembership-', '').Replace('_Regional', ' Regional')) -split "_"
            $Splitted = $MenuName -split $Replacements.SplitOn
            $Name = Format-AddSpaceToSentence -Text $Splitted[0]


            #$Name = $Name.Replace('G P O', 'GPO').Replace('L D A P', 'LDAP').Replace('K R B G T', 'KRBGT').Replace('A D', 'AD').Replace('I T R X X', 'ITRXX')

            foreach ($Replace in $Replacements.AfterSplit.Keys) {
                $Name = $Name.Replace($Replace, $Replacements.AfterSplit[$Replace])
            }

            [PSCustomObject] @{
                Name     = $Name
                NameDate = $Splitted[1]
                Href     = $Href
                Menu     = $Folder
                Date     = $File.LastWriteTime
            }
        }
    }
    $Files = $Files | Sort-Object -Property Name

    # Prepare menu based on files
    $MenuBuilder = [ordered] @{}
    foreach ($Entry in $FileS) {
        if (-not $MenuBuilder[$Entry.Menu]) {
            $MenuBuilder[$Entry.Menu] = [ordered] @{}
        }
        if (-not $MenuBuilder[$Entry.Menu][$Entry.Name]) {
            $MenuBuilder[$Entry.Menu][$Entry.Name] = $Entry
        } else {
            if ($MenuBuilder[$Entry.Menu][$Entry.Name].Date -lt $Entry.Date) {
                $MenuBuilder[$Entry.Menu][$Entry.Name] = $Entry
            }
        }
    }

    # Build report
    New-HTML {
        New-HTMLNavTop -HomeLinkHome -Logo $Logo {
            New-NavTopMenu -Name 'Reports' -IconBrands sellsy {
                foreach ($Report in $Type) {
                    if ($Report -eq 'ServiceAccounts') {
                        New-NavLink -IconRegular newspaper -Name 'Service Accounts' -InternalPageID 'ServiceAccounts'
                    }
                    if ($Report -eq 'UsersPasswordNeverExpire') {
                        New-NavLink -IconRegular newspaper -Name 'Users with PNE' -InternalPageID 'UsersPNE'
                    }
                    if ($Report -eq 'ComputersLimitedINS') {
                        New-NavLink -IconRegular newspaper -Name 'Computers in INS' -InternalPageID 'ComputersINS'
                    }
                }
            }
            foreach ($Menu in $MenuBuilder.Keys) {
                $TopMenuSplat = @{
                    Name = $Menu
                }
                if ($Configuration.Folders.$Menu.IconType) {
                    $TopMenuSplat[$Configuration.Folders.$Menu.IconType] = $Configuration.Folders.$Menu.Icon
                }
                New-NavTopMenu @TopMenuSplat {
                    foreach ($MenuReport in $MenuBuilder[$Menu].Keys) {
                        New-NavLink -IconRegular calendar-check -Name $MenuBuilder[$Menu][$MenuReport].Name -Href $MenuBuilder[$Menu][$MenuReport].Href
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
                        New-CalendarEvent -Title $CalendarEntry.Name -StartDate $CalendarEntry.Date -EndDate $($CalendarEntry.Date).AddMinutes(30) -Url $CalendarEntry.Href
                    }
                }
            }
        }
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

    } -FilePath $HTMLPath -Online -ShowHTML:$ShowHTML.IsPresent -TitleText 'AD Compliance Dashboard'

    # Export statistics to file to create charts later on
    if ($StatisticsPath) {
        $TopStats | Export-Clixml -Depth 3 -LiteralPath $StatisticsPath
    }
}