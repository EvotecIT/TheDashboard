@{
    AliasesToExport      = @()
    Author               = 'Przemyslaw Klys'
    CmdletsToExport      = @()
    CompanyName          = 'Evotec'
    CompatiblePSEditions = @('Desktop', 'Core')
    Copyright            = '(c) 2011 - 2022 Przemyslaw Klys @ Evotec. All rights reserved.'
    Description          = 'TheDashboard is a module that allows you to create a dashboard for your HTML reports'
    FunctionsToExport    = @('New-TheDashboardGage', 'Request-DashboardStatistics', 'Start-TheDashboard')
    GUID                 = '0aacc01f-5861-407e-b5e9-2bf57256fb04'
    ModuleVersion        = '0.0.8'
    PowerShellVersion    = '5.1'
    PrivateData          = @{
        PSData = @{
            Tags = @('HTML', 'Reports', 'Reporting', 'Windows')
        }
    }
    RequiredModules      = @(@{
            ModuleVersion = '0.0.251'
            ModuleName    = 'PSSharedGoods'
            Guid          = 'ee272aa8-baaa-4edf-9f45-b6d6f7d844fe'
        }, @{
            ModuleVersion = '0.0.180'
            ModuleName    = 'PSWriteHTML'
            Guid          = 'a7bdf640-f5cb-4acf-9de0-365b322d245c'
        })
    RootModule           = 'TheDashboard.psm1'
}