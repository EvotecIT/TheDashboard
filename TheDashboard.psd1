@{
    AliasesToExport      = @('New-TheDashboardFolder', 'New-TheDashboardGage', 'New-TheDashboardReplacement')
    Author               = 'Przemyslaw Klys'
    CmdletsToExport      = @()
    CompanyName          = 'Evotec'
    CompatiblePSEditions = @('Desktop', 'Core')
    Copyright            = '(c) 2011 - 2023 Przemyslaw Klys @ Evotec. All rights reserved.'
    Description          = 'TheDashboard is a module that allows you to create a dashboard for your HTML reports'
    FunctionsToExport    = @('New-DashboardFolder', 'New-DashboardGage', 'New-DashboardReplacement', 'Start-TheDashboard')
    GUID                 = '0aacc01f-5861-407e-b5e9-2bf57256fb04'
    ModuleVersion        = '0.0.10'
    PowerShellVersion    = '5.1'
    PrivateData          = @{
        PSData = @{
            Tags                       = @('HTML', 'Reports', 'Reporting', 'Windows')
            ProjectUri                 = 'https://github.com/EvotecIT/TheDashboard'
            ExternalModuleDependencies = @('Microsoft.PowerShell.Management', 'Microsoft.PowerShell.Utility')
        }
    }
    RequiredModules      = @(@{
            ModuleName    = 'PSSharedGoods'
            ModuleVersion = '0.0.259'
            Guid          = 'ee272aa8-baaa-4edf-9f45-b6d6f7d844fe'
        }, @{
            ModuleName    = 'PSWriteHTML'
            ModuleVersion = '0.0.183'
            Guid          = 'a7bdf640-f5cb-4acf-9de0-365b322d245c'
        }, 'Microsoft.PowerShell.Management', 'Microsoft.PowerShell.Utility')
    RootModule           = 'TheDashboard.psm1'
}