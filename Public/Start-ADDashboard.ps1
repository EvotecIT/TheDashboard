function Start-ADDashboard {
    [cmdletBinding()]
    param(
        [string] $HTMLPath,
        [string] $ExcelPath,
        [parameter(Mandatory)][ValidateSet('ServiceAccounts', 'UsersPasswordNeverExpire')][string[]] $Type
    )
    $Cache = @{}
    $Properties = 'DistinguishedName', 'mail', 'LastLogonDate', 'PasswordLastSet', 'DisplayName', 'Manager', 'Description', 'PasswordNeverExpires', 'PasswordNotRequired', 'PasswordExpired', 'UserPrincipalName', 'SamAccountName', 'CannotChangePassword', 'TrustedForDelegation', 'TrustedToAuthForDelegation'
    $AllUsers = Get-ADUser -Filter * -Properties $Properties
    #$AllComputers = Get-ADComputer -Filter * -Properties $PropertiesComputer
    foreach ($U in $AllUsers) {
        $Cache[$U.DistinguishedName] = $U
    }

    # Build report
    New-HTML {
        New-HTMLNavTop {
            New-NavTopMenu -Name 'Reports' -IconRegular stop-circle {
                foreach ($Report in $Type) {
                    if ($Report -eq 'ServiceAccounts') {
                        New-NavLink -IconMaterial airplane -Name 'Service Accounts' -InternalPageID 'ServiceAccounts'
                    }
                    if ($Report -eq 'UsersPasswordNeverExpire') {
                        New-NavLink -IconMaterial airplane -Name 'Users with PNE' -InternalPageID 'UsersPNE'
                    }
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
            }
        }

    } -FilePath $HTMLPath -Online -ShowHTML -TitleText 'AD Compliance Dashboard'

    # Export statistics to file to create charts later on
    #$Statistics | Export-Clixml -Depth 3 -LiteralPath $StatisticsFile
}