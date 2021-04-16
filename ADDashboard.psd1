@{
    AliasesToExport      = @()
    Author               = 'Przemyslaw Klys'
    CmdletsToExport      = @()
    CompanyName          = 'Evotec'
    CompatiblePSEditions = @('Desktop', 'Core')
    Copyright            = '(c) 2011 - 2021 Przemyslaw Klys @ Evotec. All rights reserved.'
    Description          = ''
    FunctionsToExport    = 'Start-ADDashboard'
    GUID                 = '0aacc01f-5861-407e-b5e9-2bf57256fb04'
    ModuleVersion        = '0.0.2'
    PowerShellVersion    = '5.1'
    PrivateData          = @{
        PSData = @{
            Tags = @('HTML', 'Reports', 'Reporting', 'Windows')
        }
    }
    RequiredModules      = @(@{
            ModuleVersion = '0.0.199'
            ModuleName    = 'PSSharedGoods'
            Guid          = 'ee272aa8-baaa-4edf-9f45-b6d6f7d844fe'
        })
    RootModule           = 'ADDashboard.psm1'
}