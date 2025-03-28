﻿Import-Module .\TheDashboard.psd1 -Force

# Those commands are used to fix the content of the reports generated by PingCastle or PSWriteHTML and wanting to store them on SharePoint
Repair-DashboardContent -ExtensionFrom ".html" -Directory "D:\TheDashboard\Reports\Security" -Search '<meta http-equiv="Content-Security-Policy".*?/>' -Replace '' -AddOneMinute -WhatIf
Repair-DashboardContent -ExtensionFrom ".html" -Directory "D:\TheDashboard\Reports" -Search "_|:|@|#|<-|←|<:|<%|=|=>|⇒|>:" -Replace "_|:|@|#|<-|←|<:|<-%|=|=>|⇒|>:" -EscapeRegex -AddOneMinute -WhatIf

Repair-DashboardContent -ExtensionFrom ".html" -Directory "C:\Support\GitHub\TheDashboard\Examples\Reports\WindowsUpdates" -Search '<meta http-equiv="Content-Security-Policy".*?/>' -Replace '' -AddOneMinute -WhatIf
Repair-DashboardContent -ExtensionFrom ".html" -Directory "C:\Support\GitHub\TheDashboard\Examples\Reports\DomainControllers" -Search "_|:|@|#|<-|←|<:|<%|=|=>|⇒|>:" -Replace "_|:|@|#|<-|←|<:|<-%|=|=>|⇒|>:" -EscapeRegex -AddOneMinute -WhatIf