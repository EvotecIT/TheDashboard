function Start-ADDashboard {
    [cmdletBinding()]
    param(
        [string] $HTMLPath,
        [string] $ExcelPath,
        [string] $StatisticsPath,
        [parameter(Mandatory)][ValidateSet('ServiceAccounts', 'UsersPasswordNeverExpire', 'ComputersLimitedINS')][string[]] $Type,
        [string] $Logo
    )
    $TopStats = [ordered] @{}
    $Cache = @{}
    $Properties = 'DistinguishedName', 'mail', 'LastLogonDate', 'PasswordLastSet', 'DisplayName', 'Manager', 'Description', 'PasswordNeverExpires', 'PasswordNotRequired', 'PasswordExpired', 'UserPrincipalName', 'SamAccountName', 'CannotChangePassword', 'TrustedForDelegation', 'TrustedToAuthForDelegation'
    $AllUsers = Get-ADUser -Filter * -Properties $Properties
    $PropertiesComputer = 'DistinguishedName', 'LastLogonDate', 'PasswordLastSet', 'Enabled', 'DnsHostName', 'PasswordNeverExpires', 'PasswordNotRequired', 'PasswordExpired', 'Manager', 'OperatingSystemVersion', 'OperatingSystem' , 'TrustedForDelegation'
    $AllComputers = Get-ADComputer -Filter * -Properties $PropertiesComputer
    $AllGroups = Get-ADGroup -Filter *
    $AllGroupPolicies = Get-GPO -All
    foreach ($U in $AllUsers) {
        $Cache[$U.DistinguishedName] = $U
    }
    foreach ($C in $AllComputers) {
        $Cache[$C.DistinguishedName] = $C
    }


    if ($StatisticsPath -and (Test-Path -LiteralPath $StatisticsPath)) {
        $TopStats = Import-Clixml -LiteralPath $StatisticsPath
        $TodayString = Get-Date -Format 'yyyyMMddhhmmss'
        $TopStats[$TodayString] = [ordered] @{}
        $TopStats[$TodayString]['Date'] = Get-Date
        $TopStats[$TodayString]['Computers'] = $AllComputers.Count
        $TopStats[$TodayString]['Users'] = $AllUsers.Count
        $TopStats[$TodayString]['Groups'] = $AllGroups.Count
        $TopStats[$TodayString]['Group Policies'] = $AllGroupPolicies.Count
    }

    # Build report
    New-HTML {
        New-HTMLNavTop -HomeLinkHome -Logo $Logo {
            New-NavTopMenu -Name 'Reports' -IconRegular stop-circle {
                foreach ($Report in $Type) {
                    if ($Report -eq 'ServiceAccounts') {
                        New-NavLink -IconMaterial airplane -Name 'Service Accounts' -InternalPageID 'ServiceAccounts'
                    }
                    if ($Report -eq 'UsersPasswordNeverExpire') {
                        New-NavLink -IconMaterial airplane -Name 'Users with PNE' -InternalPageID 'UsersPNE'
                    }
                    if ($Report -eq 'ComputersLimitedINS') {
                        New-NavLink -IconMaterial airplane -Name 'Computers in INS' -InternalPageID 'ComputersINS'
                    }
                }
            }
        }

        # primary page data
        New-HTMLSectionStyle -BorderRadius 0px -HeaderBackGroundColor Grey -RemoveShadow
        New-HTMLPanelStyle -BorderRadius 0px
        New-HTMLSection -Invisible {
            New-HTMLPanel {
                #New-HTMLText -Text 'Users' -Color Red -Alignment center -FontSize 20px
                New-HTMLGage -Label 'All Users' -MinValue 0 -MaxValue 80000 -Value $AllUsers.Count -Counter
            }
            New-HTMLPanel {
                #New-HTMLText -Text 'Groups' -Color Red -Alignment center -FontSize 20px
                New-HTMLGage -Label 'All Groups' -MinValue 0 -MaxValue 80000 -Value $AllGroups.Count -Counter
            }
            New-HTMLPanel {
                #New-HTMLText -Text 'Computers' -Color Red -Alignment center -FontSize 20px
                New-HTMLGage -Label 'All Computers' -MinValue 0 -MaxValue 80000 -Value $AllComputers.Count -Counter
            }
            New-HTMLPanel {
                #New-HTMLText -Text 'Users' -Color Red -Alignment center -FontSize 20px
                New-HTMLGage -Label 'All Group Policies' -MinValue 0 -MaxValue 4000 -Value $AllGroupPolicies.Count -Counter
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
                New-HTMLChart -Title 'Domain Summary' -TitleAlignment center {
                    $StatisticsKeys = $TopStats.Keys | Sort-Object | Select-Object -Last 10
                    $Dates = foreach ($Day in $StatisticsKeys) {
                        $TopStats[$Day].Date
                    }
                    $LineComputers = foreach ($Day in $StatisticsKeys) {
                        $TopStats[$Day].Computers
                    }
                    $LineUsers = foreach ($Day in $StatisticsKeys) {
                        $TopStats[$Day].Users
                    }
                    $LineGroups = foreach ($Day in $StatisticsKeys) {
                        $TopStats[$Day].Groups
                    }
                    $LineGroupPolicies = foreach ($Day in $StatisticsKeys) {
                        $TopStats[$Day].'Group Policies'
                    }
                    New-ChartAxisX -Type datetime -Names $Dates
                    New-ChartAxisY -TitleText 'Numbers' -Show
                    New-ChartLine -Name 'Computers' -Value $LineComputers
                    New-ChartLine -Name 'Users' -Value $LineUsers
                    New-ChartLine -Name 'Groups' -Value $LineGroups
                    New-ChartLine -Name 'Group Policies' -Value $LineGroupPolicies
                }
            }
        }
        foreach ($Report in $Type) {
            if ($Report -eq 'ServiceAccounts') {
                New-HTMLPage -Name 'ServiceAccounts' {
                    #$ReportTitle = 'Service Accounts'
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

    } -FilePath $HTMLPath -Online -ShowHTML -TitleText 'AD Compliance Dashboard'

    # Export statistics to file to create charts later on
    if ($StatisticsPath) {
        $TopStats | Export-Clixml -Depth 3 -LiteralPath $StatisticsPath
    }
}