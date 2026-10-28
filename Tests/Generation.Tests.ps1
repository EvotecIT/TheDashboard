BeforeAll {
    $ModulePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'TheDashboard.psd1'
    Import-Module $ModulePath -Force -ErrorAction Stop
    $script:DashboardModule = Get-Module TheDashboard
    function New-TestReports {
        <#
        .SYNOPSIS
        Writes small report fixtures with their filenames visible in the document.

        .PARAMETER Root
        Test-owned directory to create when needed.

        .PARAMETER Names
        Report filenames to write beneath Root.
        #>
        param(
            [string] $Root,
            [string[]] $Names
        )
        $null = [IO.Directory]::CreateDirectory($Root)
        foreach ($Name in $Names) {
            [IO.File]::WriteAllText((Join-Path $Root $Name), "<html><body><h1>$Name</h1></body></html>")
        }
    }
    function Invoke-TestDashboard {
        <#
        .SYNOPSIS
        Runs the shared report, naming, retention, and gauge fixture.

        .PARAMETER Root
        Test-owned dashboard output directory containing the Reports subdirectory.

        .PARAMETER TestMode
        Requests planning without dashboard writes.

        .PARAMETER WhatIf
        Requests the command's ShouldProcess preview.

        .PARAMETER Online
        Uses CDN resources to reduce generated fixture size when embedding is unnecessary.

        .PARAMETER Logo
        Optional presentation setting used to exercise cache invalidation.

        .PARAMETER Force
        Requests regeneration of existing child pages.

        .PARAMETER RemoveNotIncluded
        Exercises raw-report deletion using RemoveItem within the test directory.
        #>
        param(
            [string] $Root,
            [switch] $TestMode,
            [switch] $WhatIf,
            [switch] $Online,
            [string] $Logo,
            [switch] $Force,
            [switch] $RemoveNotIncluded
        )
        $ReportRoot = Join-Path $Root 'Reports'
        Start-TheDashboard -HTMLPath (Join-Path $Root 'Index.html') -StatisticsPath (Join-Path $Root 'Stats.xml') -Logo $Logo -Online:$Online -Force:$Force -TestMode:$TestMode -WhatIf:$WhatIf -RemoveNotIncluded:$RemoveNotIncluded -DeleteMethod RemoveItem -PassThru {
            New-DashboardFolder -Name 'Reports' -UrlName 'Reports' -Path $ReportRoot
            New-DashboardReplacement -SplitOn '[_-]' -AfterSplitPositionName @{
                '*'                   = 0
                'PingCastle-Domain-*' = 0, 2
            }
            New-DashboardLimit -LimitItem 1 -IncludeHistory
            New-DashboardGage -Label 'Users' -MinValue 0 -MaxValue 100 -Value 12 -Date ([datetime] '2026-10-03')
        }
    }
}

Describe 'Filename rules and report identity' {
    It 'selects the specific rule ahead of a wildcard in an ordinary hashtable' {
        & $script:DashboardModule {
            (Get-DashboardNamePositions -Name 'PingCastle-Domain-corp.example_2026-10-02_090000' -Rules @{
                '*'                   = 0
                'PingCastle-Domain-*' = 0, 2
            }) -join ','
        } | Should -Be '0,2'
    }

    It 'honors explicit precedence while keeping star as the fallback' {
        & $script:DashboardModule {
            Get-DashboardNamePositions -Name 'ReportABC' -Rules ([ordered] @{
                    '*'         = 2
                    'Report*'   = 1
                    'ReportABC' = 0
                })
        } | Should -Be 1
    }

    It 'rejects ambiguous equal specificity and invalid split positions' {
        { & $script:DashboardModule { Get-DashboardNamePositions -Name 'AB' -Rules @{
                    'A?' = 0
                    '?B' = 1
                } } } | Should -Throw '*Equally specific*'
        { & $script:DashboardModule { Convert-DashboardReportName -Name 'One_Two' -Replacements @{
                    SplitOn                = '_'
                    AfterSplitPositionName = 3
                } } } | Should -Throw '*outside*'
    }

    It 'keeps parent, child, and hyphenated domains separate and groups only their versions' {
        $Root = Join-Path $TestDrive 'identity'
        New-TestReports -Root (Join-Path $Root 'Reports') -Names @(
            'PingCastle-Domain-example.test_2026-10-02_090000.html',
            'PingCastle-Domain-group.example.test_2026-10-02_090000.html',
            'PingCastle-Domain-corp-east.example.test_2026-10-02_090000.html',
            'PingCastle-Domain-corp-west.example.test_2026-10-02_090000.html',
            'PingCastle-Domain-corp-east.example.test_2026-10-01_090000.html'
        )
        $Result = Invoke-TestDashboard -Root $Root -TestMode
        $Result.MenuBuilder.Reports.Count | Should -Be 4
        $East = $Result.MenuBuilder.Reports['pingcastle-domain-corp-east.example.test']
        $East.Full.Count | Should -Be 1
        $East.History.Count | Should -Be 1
        @($Result.MenuBuilder.Reports.Values.Current.PageName | Sort-Object -Unique).Count | Should -Be 4
        $East.Current.Name | Should -Match 'corp-east.example.test'
    }

    It 'assigns distinct filenames to labels that sanitize to the same name' {
        $Root = Join-Path $TestDrive 'collision'
        New-TestReports -Root (Join-Path $Root 'Reports') -Names 'A B.html', 'A_B.html', 'A-B.html'
        $Result = Start-TheDashboard -HTMLPath (Join-Path $Root 'Index.html') -TestMode -PassThru {
            New-DashboardFolder -Name Reports -UrlName Reports -Path (Join-Path $Root 'Reports')
            New-DashboardReplacement -BeforeSplit @{
                'A-B' = 'A:B'
            }
        }
        @($Result.MenuBuilder.Reports.Values.Current.PageName | Sort-Object -Unique).Count | Should -Be 3
        @($Result.FilePathsGenerated | Sort-Object -Unique).Count | Should -Be $Result.FilePathsGenerated.Count
    }

    It 'uses the filename timestamp rather than a changed modification time' {
        $Root = Join-Path $TestDrive 'date'
        New-TestReports -Root (Join-Path $Root 'Reports') -Names 'Report_2026-10-02_090000.html', 'Report_2026-10-01_090000.html'
        [IO.File]::SetLastWriteTime((Join-Path $Root 'Reports/Report_2026-10-01_090000.html'), [datetime] '2030-01-01')
        $Result = Invoke-TestDashboard -Root $Root -TestMode
        $Result.MenuBuilder.Reports['report'].Current.Date | Should -Be ([datetime] '2026-10-02T09:00:00')
    }

    It 'groups CleanupMonster reports with separated time components into history' {
        $Root = Join-Path $TestDrive 'cleanup-timestamps'
        New-TestReports -Root (Join-Path $Root 'Reports') -Names 'CleanupCloudDevices_2026-09-23_17_51_30.html', 'CleanupCloudDevices_2026-09-22_18_13_14.html', 'OtherReport_2026-09-23_175130.html'
        $Result = Invoke-TestDashboard -Root $Root -TestMode
        $Result.MenuBuilder.Reports.Count | Should -Be 2
        $Group = $Result.MenuBuilder.Reports['cleanupclouddevices']
        $Group.Current.Date | Should -Be ([datetime] '2026-09-23T17:51:30')
        $Group.Full.Count | Should -Be 1
        $Group.History.Count | Should -Be 1
    }

    It 'groups observed timestamp formats into one menu link per report with filename dates' {
        $Root = Join-Path $TestDrive 'observed-filenames'
        New-TestReports -Root (Join-Path $Root 'Reports') -Names @(
            'CleanupComputers_2026-07-22_06_02_12.html'
            'CleanupComputers_2026-07-23_06_02_11.html'
            'CriticalGroups_2026-10-19_04_24_02.html'
            'CriticalGroups_2026-10-26_04_22_07.html'
            'Testimo_DomainComputersUnsupported_2026-10-01_010353.html'
            'Testimo_DomainComputersUnsupported_2026-10-08_010428.html'
            'ADEssentials_BrokenProtectedFromDeletion_2026-01-02_081603.html'
            'ADEssentials_BrokenProtectedFromDeletion_2026-01-09_084052.html'
            'GraphEssentials_Applications_2026-05-01_132028.html'
            'GraphEssentials_Applications_2026-05-08_131952.html'
            'WindowsUpdateReporting_2026-03-09-090007.html'
            'WindowsUpdateReporting_2026-03-10-090007.html'
            'ForestReplicationSummary_2026-04-01-033003.html'
            'ForestReplicationSummary_2026-04-01-093003.html'
        )
        [IO.File]::SetLastWriteTime((Join-Path $Root 'Reports/WindowsUpdateReporting_2026-03-09-090007.html'), [datetime] '2030-01-01')
        $Result = Start-TheDashboard -HTMLPath (Join-Path $Root 'Index.html') -Online -PassThru {
            New-DashboardFolder -Name Reports -UrlName Reports -Path (Join-Path $Root 'Reports')
            New-DashboardReplacement -SplitOn '[_-]' -BeforeSplit ([ordered] @{ 'Testimo_' = ''; 'ADEssentials_' = ''; 'GraphEssentials_' = '' }) -AfterSplit @{ 'Windows Update Reporting' = 'Windows Updates' } -AddSpaceToName -AfterSplitPositionName ([ordered] @{ '*' = 0 })
            New-DashboardLimit -LimitItem 1 -IncludeHistory
        }
        $Result.MenuBuilder.Reports.Count | Should -Be 7
        $Index = [IO.File]::ReadAllText((Join-Path $Root 'Index.html'))
        foreach ($Group in $Result.MenuBuilder.Reports.Values) {
            $Group.Full.Count | Should -Be 1
            $Group.History.Count | Should -Be 1
            $Href = 'href="' + [uri]::EscapeDataString($Group.Current.PageName) + '"'
            [regex]::Matches($Index, [regex]::Escape($Href)).Count | Should -Be 1
        }
        $Result.MenuBuilder.Reports['testimo_domaincomputersunsupported'].Current.Name | Should -Be 'Domain Computers Unsupported'
        $Result.MenuBuilder.Reports['adessentials_brokenprotectedfromdeletion'].Current.Name | Should -Be 'Broken Protected From Deletion'
        $Result.MenuBuilder.Reports['graphessentials_applications'].Current.Name | Should -Be 'Applications'
        $Updates = $Result.MenuBuilder.Reports['windowsupdatereporting']
        $Updates.Current.Name | Should -Be 'Windows Updates'
        $Updates.Current.Date | Should -Be ([datetime] '2026-03-10T09:00:07')
        $Updates.History[0].Date | Should -Be ([datetime] '2026-03-09T09:00:07')
        $Replication = $Result.MenuBuilder.Reports['forestreplicationsummary']
        $Replication.Current.Date | Should -Be ([datetime] '2026-04-01T09:30:03')
        $Replication.History[0].Date | Should -Be ([datetime] '2026-04-01T03:30:03')
    }
}

Describe 'Retention and safe planning' {
    It 'omits year-old versions from delivery while preserving recent history and the latest report' -TestCases @(
        @{ SnapshotLimit = 1; FullCount = 1; HistoryCount = 1 },
        @{ SnapshotLimit = 7; FullCount = 2; HistoryCount = 0 }
    ) {
        param($SnapshotLimit, $FullCount, $HistoryCount)
        $Root = Join-Path $TestDrive "delivery-window-$SnapshotLimit"
        $Now = Get-Date
        $RecentName = 'WindowsUpdateReporting_' + $Now.AddDays(-2).ToString('yyyy-MM-dd-HHmmss') + '.html'
        $HistoryName = 'WindowsUpdateReporting_' + $Now.AddDays(-8).ToString('yyyy-MM-dd-HHmmss') + '.html'
        $OldName = 'WindowsUpdateReporting_' + $Now.AddDays(-366).ToString('yyyy-MM-dd-HHmmss') + '.html'
        $DormantName = 'DormantReport_' + $Now.AddDays(-400).ToString('yyyy-MM-dd-HHmmss') + '.html'
        New-TestReports -Root (Join-Path $Root 'Reports') -Names $RecentName, $HistoryName, $OldName, $DormantName
        $Result = Start-TheDashboard -HTMLPath (Join-Path $Root 'Index.html') -Online -PassThru {
            New-DashboardFolder -Name Reports -UrlName Reports -Path (Join-Path $Root 'Reports')
            New-DashboardLimit -LimitItem $SnapshotLimit -LimitDays 90 -IncludeHistory -IncludeHistoryLimitDays 90
        }
        $Updates = $Result.MenuBuilder.Reports['windowsupdatereporting']
        $Updates.Full.Count | Should -Be $FullCount
        $Updates.History.Count | Should -Be $HistoryCount
        $DeliveredReports = @($Result.FilesToKeepOrRemove | Where-Object { $_.Type -eq 'Report' -and $_.Include } | ForEach-Object { [IO.Path]::GetFileName($_.Path) })
        $DeliveredReports | Should -HaveCount 3
        $DeliveredReports | Should -Contain $RecentName
        $DeliveredReports | Should -Contain $HistoryName
        $DeliveredReports | Should -Contain $DormantName
        $DeliveredReports | Should -Not -Contain $OldName
        @($Result.FilePathsGenerated | Where-Object { [IO.Path]::GetFileName($_) -eq ('Reports_' + $OldName) }).Count | Should -Be 0
        Test-Path -LiteralPath (Join-Path $Root "Reports/$OldName") | Should -BeTrue
    }

    It 'applies named retention limits even when duplicate labels are disambiguated' {
        $Root = Join-Path $TestDrive 'named-retention'
        New-TestReports -Root (Join-Path $Root 'Reports') -Names 'One_2026-10-02_090000.html', 'One_2026-10-01_090000.html', 'Two_2026-10-02_090000.html', 'Two_2026-10-01_090000.html'
        $Result = Start-TheDashboard -HTMLPath (Join-Path $Root 'Index.html') -TestMode -PassThru {
            New-DashboardFolder -Name Reports -UrlName Reports -Path (Join-Path $Root 'Reports')
            New-DashboardReplacement -SplitOn '_' -BeforeSplit @{
                'One' = 'Report'
                'Two' = 'Report'
            }
            New-DashboardLimit -Name Report -LimitItem 1
        }
        $Result.MenuBuilder.Reports.Count | Should -Be 2
        @($Result.Files | Where-Object Include).Count | Should -Be 2
    }

    It 'excludes older raw reports from upload when history is disabled' {
        $Root = Join-Path $TestDrive 'retention'
        New-TestReports -Root (Join-Path $Root 'Reports') -Names 'Report_2026-10-02_090000.html', 'Report_2026-10-01_090000.html'
        $Result = Start-TheDashboard -HTMLPath (Join-Path $Root 'Index.html') -TestMode -PassThru {
            New-DashboardFolder -Name Reports -UrlName Reports -Path (Join-Path $Root 'Reports')
            New-DashboardLimit -LimitItem 1
        }
        @($Result.Files | Where-Object Include).Count | Should -Be 1
        $Result.MenuBuilder.Reports.report.History.Count | Should -Be 0
        $Result.FilePathsGenerated.Count | Should -Be 3
        @($Result.FilesToKeepOrRemove | Where-Object { $_.Type -eq 'Report' -and $_.Include }).Count | Should -Be 1
    }

    It 'preserves a shared raw report retained by another section' -TestCases @(
        @{
            Method = 'RemoveItem'
        }, @{
            Method = 'DotNetDelete'
        }
    ) {
        param(
            $Method
        )
        $Root = Join-Path $TestDrive ("shared-retention-$Method")
        $ReportRoot = Join-Path $Root 'Reports'
        New-TestReports -Root $ReportRoot -Names 'Report_2026-10-03_090000.html', 'Report_2026-10-02_090000.html', 'Report_2026-10-01_090000.html'
        $Result = Start-TheDashboard -HTMLPath (Join-Path $Root 'Index.html') -Online -RemoveNotIncluded -DeleteMethod $Method -PassThru {
            New-DashboardFolder -Name Latest -UrlName Latest -Path $ReportRoot -DisableGlobalLimits { New-DashboardLimit -LimitItem 1 }
            New-DashboardFolder -Name Archive -UrlName Archive -Path $ReportRoot -DisableGlobalLimits { New-DashboardLimit -LimitItem 1 -IncludeHistory -IncludeHistoryLimit 1 }
        }
        Test-Path -LiteralPath (Join-Path $ReportRoot 'Report_2026-10-02_090000.html') | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $ReportRoot 'Report_2026-10-01_090000.html') | Should -BeFalse
        @($Result.FilesToKeepOrRemove | Where-Object { $_.Type -eq 'Report' -and $_.Include }).Count | Should -Be 2
        @($Result.FilesToKeepOrRemove | Where-Object { $_.Path -eq (Join-Path $ReportRoot 'Report_2026-10-02_090000.html') }).Count | Should -Be 1
        $Result.MenuBuilder.Archive.report.History.Count | Should -Be 1
    }

    It 'does not write HTML, statistics, manifests, logs, or locks in either preview mode' -TestCases @(
        @{
            Mode = 'TestMode'
        }, @{
            Mode = 'WhatIf'
        }
    ) {
        param(
            $Mode
        )
        $Root = Join-Path $TestDrive $Mode
        New-TestReports -Root (Join-Path $Root 'Reports') -Names 'Report_2026-10-02_090000.html'
        $Arguments = @{
            Root = $Root
        }
        $Arguments[$Mode] = $true
        $Result = Invoke-TestDashboard @Arguments
        $Result.Preview | Should -BeTrue
        @(Get-ChildItem -LiteralPath $Root -File -Force).Count | Should -Be 0
        $Result.FilePathsGenerated.Count | Should -Be 3
    }

    It 'previews a new CopyFrom destination without copying inputs' {
        $Source = Join-Path $TestDrive 'external'
        $Root = Join-Path $TestDrive 'preview-copy'
        New-TestReports -Root $Source -Names 'Report_2026-10-02_090000.html'
        $Result = Start-TheDashboard -HTMLPath (Join-Path $Root 'Index.html') -TestMode -PassThru {
            New-DashboardFolder -Name Reports -UrlName Reports -Path ((Join-Path $Root 'Reports') + [IO.Path]::DirectorySeparatorChar) -CopyFrom $Source
            New-DashboardFolder -Name Archive -UrlName Archive -Path (Join-Path $Root 'Reports') -CopyFrom $Source
        }
        $Result.Files.Count | Should -Be 2
        $Result.MenuBuilder.Archive.Count | Should -Be 1
        @($Result.FilesToKeepOrRemove | Where-Object Type -eq Report).Count | Should -Be 1
        Test-Path -LiteralPath $Root | Should -BeFalse
    }

    It 'suppresses inherited logging defaults during preview' -TestCases @(
        @{
            Mode = 'TestMode'
        }, @{
            Mode = 'WhatIf'
        }
    ) {
        param(
            $Mode
        )
        $Root = Join-Path $TestDrive ("inherited-log-$Mode")
        New-TestReports -Root (Join-Path $Root 'Reports') -Names 'Report_2026-10-02_090000.html'
        $Log = Join-Path $Root 'previous.log'
        [IO.File]::WriteAllText($Log, 'Previous run')
        $Before = (Get-FileHash -LiteralPath $Log).Hash
        & $script:DashboardModule {
            param(
                $Log,
                $Root,
                $Mode
            )
            $PreviousDefaults = $Script:PSDefaultParameterValues
            try {
                $Script:PSDefaultParameterValues = @{
                    'Write-Color:LogFile' = $Log
                }
                $Arguments = @{
                    HTMLPath = (Join-Path $Root 'Index.html')
                    LogPath  = (Join-Path $Root 'new.log')
                }
                $Arguments[$Mode] = $true
                Start-TheDashboard @Arguments { New-DashboardFolder -Name Reports -UrlName Reports -Path (Join-Path $Root 'Reports') }
            } finally {
                $Script:PSDefaultParameterValues = $PreviousDefaults
            }
        } $Log $Root $Mode
        (Get-FileHash -LiteralPath $Log).Hash | Should -Be $Before
        Test-Path -LiteralPath (Join-Path $Root 'new.log') | Should -BeFalse
    }

    It 'includes supporting assets in deployment without creating menu entries' -TestCases @(
        @{
            Preview = $true
        }, @{
            Preview = $false
        }
    ) {
        param(
            $Preview
        )
        $Root = Join-Path $TestDrive ("assets-$Preview")
        $Source = Join-Path $TestDrive ("asset-source-$Preview")
        New-TestReports -Root $Source -Names 'Report_2026-10-02_090000.html'
        New-TestReports -Root (Join-Path $Source 'assets') -Names 'report.css', 'report.js', 'unconfigured.txt'
        $Elements = {
            New-DashboardFolder -Name Reports -UrlName Reports -Path (Join-Path $Root 'Reports') -CopyFrom $Source -Extension '.css', '.js'
        }
        $Result = Start-TheDashboard -HTMLPath (Join-Path $Root 'Index.html') -Online -TestMode:$Preview -PassThru $Elements
        $Result.MenuBuilder.Reports.Count | Should -Be 1
        $Assets = @($Result.FilesToKeepOrRemove | Where-Object Type -eq Asset)
        $Assets.Count | Should -Be 2
        @($Assets | Where-Object Include).Count | Should -Be 2
        foreach ($Asset in $Assets) {
            $Asset.Path | Should -Match 'Reports[\\/]assets[\\/]report\.(css|js)$'
            (Test-Path -LiteralPath $Asset.Path) | Should -Be (-not $Preview)
        }
        if (-not $Preview) {
            $Existing = Start-TheDashboard -HTMLPath (Join-Path $Root 'Index.html') -Online -PassThru {
                New-DashboardFolder -Name Reports -UrlName Reports -Path (Join-Path $Root 'Reports') -Extension '.css', '.js'
            }
            @($Existing.FilesToKeepOrRemove | Where-Object Type -eq Asset).Count | Should -Be 2
        }
    }

    It 'plans an asset-only destination before the first report arrives' -TestCases @(
        @{
            Preview = $true
        }, @{
            Preview = $false
        }
    ) {
        param(
            $Preview
        )
        $Root = Join-Path $TestDrive ("asset-only-$Preview")
        $Source = Join-Path $TestDrive ("asset-only-source-$Preview")
        New-TestReports -Root (Join-Path $Source 'assets') -Names 'report.css'
        $Result = Start-TheDashboard -HTMLPath (Join-Path $Root 'Index.html') -Online -TestMode:$Preview -PassThru {
            New-DashboardFolder -Name Reports -UrlName Reports -Path (Join-Path $Root 'Reports') -CopyFrom $Source -Extension '.css'
        }
        $Result.Files.Count | Should -Be 0
        @($Result.FilesToKeepOrRemove | Where-Object Type -eq Asset).Count | Should -Be 1
        (Test-Path -LiteralPath (Join-Path $Root 'Reports/assets/report.css')) | Should -Be (-not $Preview)
    }

    It 'fails on a collector error, unsupported element, or missing report folder before publishing' {
        $Root = Join-Path $TestDrive 'failures'
        New-TestReports -Root $Root -Names 'Index.html', 'Unrelated.html'
        $Before = (Get-FileHash -LiteralPath (Join-Path $Root 'Index.html')).Hash
        { Start-TheDashboard -HTMLPath (Join-Path $Root 'Index.html') { throw 'Collector failed' } } | Should -Throw '*Collector failed*'
        { Start-TheDashboard -HTMLPath (Join-Path $Root 'Index.html') { @{
                    Type = 'Notification'
                } } } | Should -Throw '*not supported*'
        { Start-TheDashboard -HTMLPath (Join-Path $Root 'Index.html') { New-DashboardFolder -Name Reports -UrlName Reports -Path (Join-Path $Root 'Absent') } } | Should -Throw '*does not exist*'
        (Get-FileHash -LiteralPath (Join-Path $Root 'Index.html')).Hash | Should -Be $Before
        Test-Path -LiteralPath (Join-Path $Root 'Unrelated.html') | Should -BeTrue
        @(Get-ChildItem -LiteralPath $Root -Force -Filter '.dashboard-stage-*').Count | Should -Be 0
    }
}

Describe 'Generated pages and incremental publishing' {
    It 'generates separate domain navigation and repairs a missing cached page' {
        $Root = Join-Path $TestDrive 'render'
        New-TestReports -Root (Join-Path $Root 'Reports') -Names 'PingCastle-Domain-example.test_2026-10-02_090000.html', 'PingCastle-Domain-group.example.test_2026-10-02_090000.html'
        $First = Invoke-TestDashboard -Root $Root -Online
        $First.FilePathsGenerated.Count | Should -Be 5
        foreach ($Path in $First.FilePathsGenerated) {
            Test-Path -LiteralPath $Path -PathType Leaf | Should -BeTrue
        }
        $HTML = Get-Content -LiteralPath (Join-Path $Root 'Index.html') -Raw
        $HTML | Should -Match '"data"\s*:\s*\[\s*12\s*\]'
        foreach ($Entry in $First.MenuBuilder.Reports.Values.Current) {
            $HTML | Should -Match ([regex]::Escape([uri]::EscapeDataString($Entry.PageName)))
            $Page = Get-Content -LiteralPath (Join-Path $Root $Entry.PageName) -Raw
            $Page | Should -Match ([regex]::Escape($Entry.Href))
        }
        $Second = Invoke-TestDashboard -Root $Root -Online
        @($Second.MenuBuilder.Reports.Values.Current | Where-Object SkipGeneration).Count | Should -Be 2
        $Missing = Join-Path $Root (@($Second.MenuBuilder.Reports.Values)[0].Current.PageName)
        Remove-Item -LiteralPath $Missing
        $Third = Invoke-TestDashboard -Root $Root -Online
        Test-Path -LiteralPath $Missing | Should -BeTrue
        @($Third.MenuBuilder.Reports.Values.Current | Where-Object SkipGeneration).Count | Should -Be 1
    }

    It 'invalidates child pages when navigation or presentation configuration changes' {
        $Root = Join-Path $TestDrive 'invalidate'
        New-TestReports -Root (Join-Path $Root 'Reports') -Names 'One_2026-10-02_090000.html'
        $null = Invoke-TestDashboard -Root $Root -Online
        $Changed = Invoke-TestDashboard -Root $Root -Online -Logo 'https://example.test/logo.png'
        $Changed.MenuBuilder.Reports.one.Current.SkipGeneration | Should -BeFalse
        New-TestReports -Root (Join-Path $Root 'Reports') -Names 'Two_2026-10-02_090000.html'
        $Added = Invoke-TestDashboard -Root $Root -Online -Logo 'https://example.test/logo.png'
        $Added.MenuBuilder.Reports.one.Current.SkipGeneration | Should -BeFalse
        (Get-Content -LiteralPath (Join-Path $Root $Added.MenuBuilder.Reports.one.Current.PageName) -Raw) | Should -Match 'Reports_Two.html'
    }

    It 'removes only previously owned pages and preserves unrelated HTML' {
        $Root = Join-Path $TestDrive 'owned'
        New-TestReports -Root (Join-Path $Root 'Reports') -Names 'One_2026-10-02_090000.html', 'Two_2026-10-02_090000.html'
        New-TestReports -Root $Root -Names 'Unrelated.html'
        $First = Invoke-TestDashboard -Root $Root -Online
        $OldPage = Join-Path $Root $First.MenuBuilder.Reports.two.Current.PageName
        Remove-Item -LiteralPath (Join-Path $Root 'Reports/Two_2026-10-02_090000.html')
        $null = Invoke-TestDashboard -Root $Root -Online
        Test-Path -LiteralPath $OldPage | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $Root 'Unrelated.html') | Should -BeTrue
    }

    It 'rolls back a partial publication when a later destination fails' {
        $Root = Join-Path $TestDrive 'rollback'
        New-TestReports -Root $Root -Names 'Old.html', 'New.html'
        $Before = [IO.File]::ReadAllText((Join-Path $Root 'Old.html'))
        $Source = Join-Path $Root 'New.html'
        $Destination = Join-Path $Root 'Old.html'
        { & $script:DashboardModule {
                param(
                    $Source,
                    $Destination,
                    $Root
                )
                Publish-DashboardFiles -Files @(
                    @{
                        Source      = $Source
                        Destination = $Destination
                    }, @{
                        Source      = (Join-Path $Root 'Missing.html')
                        Destination = (Join-Path $Root 'Other.html')
                    }
                )
            } $Source $Destination $Root } | Should -Throw
        [IO.File]::ReadAllText($Destination) | Should -Be $Before
        @(Get-ChildItem -LiteralPath $Root -Filter '*.tmp*').Count | Should -Be 0
    }

    It 'preserves published pages and state when rendering fails and leaves move sources intact' {
        $Root = Join-Path $TestDrive 'render-failure'
        $Source = Join-Path $TestDrive 'move-failure'
        New-TestReports -Root (Join-Path $Root 'Reports') -Names 'One_2026-10-02_090000.html'
        $First = Invoke-TestDashboard -Root $Root -Online
        $Before = @($First.FilePathsGenerated + (Join-Path $Root 'Stats.xml') + $First.ManifestPath | ForEach-Object { (Get-FileHash -LiteralPath $_).Hash })
        New-TestReports -Root $Source -Names 'Two_2026-10-02_090000.html'
        Mock New-HTML -ModuleName TheDashboard { throw 'Renderer failed' }
        { Start-TheDashboard -HTMLPath (Join-Path $Root 'Index.html') -StatisticsPath (Join-Path $Root 'Stats.xml') -Online {
                New-DashboardFolder -Name Reports -UrlName Reports -Path (Join-Path $Root 'Reports') -MoveFrom $Source
            } } | Should -Throw '*Renderer failed*'
        $After = @($First.FilePathsGenerated + (Join-Path $Root 'Stats.xml') + $First.ManifestPath | ForEach-Object { (Get-FileHash -LiteralPath $_).Hash })
        $After -join ',' | Should -Be ($Before -join ',')
        Test-Path -LiteralPath (Join-Path $Source 'Two_2026-10-02_090000.html') | Should -BeTrue
        @(Get-ChildItem -LiteralPath $Root -Force -Filter '.dashboard-stage-*').Count | Should -Be 0
        Test-Path -LiteralPath (Join-Path $Root 'Index.html.lock') | Should -BeFalse
    }

    It 'rejects an incomplete renderer even when old output pages exist' {
        $Root = Join-Path $TestDrive 'incomplete-render'
        New-TestReports -Root (Join-Path $Root 'Reports') -Names 'One_2026-10-02_090000.html'
        $First = Invoke-TestDashboard -Root $Root -Online
        $Before = (Get-FileHash -LiteralPath (Join-Path $Root 'Index.html')).Hash
        Mock New-HTML -ModuleName TheDashboard {}
        { Invoke-TestDashboard -Root $Root -Online -Force } | Should -Throw '*did not produce*'
        (Get-FileHash -LiteralPath (Join-Path $Root 'Index.html')).Hash | Should -Be $Before
    }

    It 'skips unchanged copies and removes MoveFrom sources only after success' {
        $Source = Join-Path $TestDrive 'copy-source'
        $Root = Join-Path $TestDrive 'copy'
        New-TestReports -Root $Source -Names 'Report_2026-10-02_090000.html'
        $Elements = {
            New-DashboardFolder -Name Reports -UrlName Reports -Path (Join-Path $Root 'Reports') -CopyFrom $Source
        }
        $null = Start-TheDashboard -HTMLPath (Join-Path $Root 'Index.html') -Online $Elements
        $Destination = Join-Path $Root 'Reports/Report_2026-10-02_090000.html'
        $Before = (Get-Item -LiteralPath $Destination).LastWriteTimeUtc
        $ReadLock = [IO.File]::Open($Destination, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
        try {
            $null = Start-TheDashboard -HTMLPath (Join-Path $Root 'Index.html') -Online $Elements
        } finally {
            $ReadLock.Dispose()
        }
        (Get-Item -LiteralPath $Destination).LastWriteTimeUtc | Should -Be $Before
        [IO.File]::WriteAllText((Join-Path $Source 'Report_2026-10-02_090000.html'), '<html><body>Updated report</body></html>')
        $null = Start-TheDashboard -HTMLPath (Join-Path $Root 'Index.html') -Online $Elements
        [IO.File]::ReadAllText($Destination) | Should -Match 'Updated report'
        $null = Start-TheDashboard -HTMLPath (Join-Path $Root 'Index.html') -Online {
            New-DashboardFolder -Name Reports -UrlName Reports -Path (Join-Path $Root 'Reports') -MoveFrom $Source
        }
        Test-Path -LiteralPath (Join-Path $Source 'Report_2026-10-02_090000.html') | Should -BeFalse
    }
}
