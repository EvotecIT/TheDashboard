Import-Module .\ADDashboard.psd1 -Force

Start-ADDashboard -Type UsersPasswordNeverExpire, ServiceAccounts -HTMLPath $PSScriptRoot\Reports\Report.html -ExcelPath $PSScriptRoot\ReportExcel.xlsx