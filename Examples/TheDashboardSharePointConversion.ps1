Import-Module .\TheDashboard.psd1 -Force

Repair-DashboardExtension -Path $PSScriptRoot\Reports -ExtensionFrom ".html" -ExtensionTo ".aspx" -WhatIf
Repair-DashboardExtension -Path $PSScriptRoot\Reports -ExtensionFrom ".aspx" -ExtensionTo ".html" -WhatIf