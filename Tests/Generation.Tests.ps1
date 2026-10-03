BeforeAll {
    $ModulePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'TheDashboard.psd1'
    Import-Module $ModulePath -Force -ErrorAction Stop
    $script:DashboardModule = Get-Module TheDashboard
    function New-TestReports {
        param([string] $Root, [string[]] $Names)
        $null = [IO.Directory]::CreateDirectory($Root)
        foreach ($Name in $Names) {
            [IO.File]::WriteAllText((Join-Path $Root $Name), "<html><body><h1>$Name</h1></body></html>")
        }
    }
    function Invoke-TestDashboard {
        param([string] $Root, [switch] $TestMode, [switch] $WhatIf, [switch] $Online, [string] $Logo, [switch] $Force, [switch] $RemoveNotIncluded)
        $ReportRoot = Join-Path $Root 'Reports'
        Start-TheDashboard -HTMLPath (Join-Path $Root 'Index.html') -StatisticsPath (Join-Path $Root 'Stats.xml') -Logo $Logo -Online:$Online -Force:$Force -TestMode:$TestMode -WhatIf:$WhatIf -RemoveNotIncluded:$RemoveNotIncluded -DeleteMethod RemoveItem -PassThru {
            New-DashboardFolder -Name 'Reports' -UrlName 'Reports' -Path $ReportRoot
            New-DashboardReplacement -SplitOn '[_-]' -AfterSplitPositionName @{ '*' = 0; 'PingCastle-Domain-*' = 0, 2 }
            New-DashboardLimit -LimitItem 1 -IncludeHistory
            New-DashboardGage -Label 'Users' -MinValue 0 -MaxValue 100 -Value 12 -Date ([datetime] '2026-10-03')
        }
    }
}

Describe 'Filename rules and report identity' {
    It 'selects the specific rule ahead of a wildcard in an ordinary hashtable' {
        & $script:DashboardModule {
            (Get-DashboardNamePositions -Name 'PingCastle-Domain-corp.example_2026-10-02_090000' -Rules @{ '*' = 0; 'PingCastle-Domain-*' = 0, 2 }) -join ','
        } | Should -Be '0,2'
    }

    It 'honors explicit precedence while keeping star as the fallback' {
        & $script:DashboardModule {
            Get-DashboardNamePositions -Name 'ReportABC' -Rules ([ordered] @{ '*' = 2; 'Report*' = 1; 'ReportABC' = 0 })
        } | Should -Be 1
    }

    It 'rejects ambiguous equal specificity and invalid split positions' {
        { & $script:DashboardModule { Get-DashboardNamePositions -Name 'AB' -Rules @{ 'A?' = 0; '?B' = 1 } } } | Should -Throw '*Equally specific*'
        { & $script:DashboardModule { Convert-DashboardReportName -Name 'One_Two' -Replacements @{ SplitOn = '_'; AfterSplitPositionName = 3 } } } | Should -Throw '*outside*'
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
            New-DashboardReplacement -BeforeSplit @{ 'A-B' = 'A:B' }
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
}

Describe 'Retention and safe planning' {
    It 'applies named retention limits even when duplicate labels are disambiguated' {
        $Root = Join-Path $TestDrive 'named-retention'
        New-TestReports -Root (Join-Path $Root 'Reports') -Names 'One_2026-10-02_090000.html', 'One_2026-10-01_090000.html', 'Two_2026-10-02_090000.html', 'Two_2026-10-01_090000.html'
        $Result = Start-TheDashboard -HTMLPath (Join-Path $Root 'Index.html') -TestMode -PassThru {
            New-DashboardFolder -Name Reports -UrlName Reports -Path (Join-Path $Root 'Reports')
            New-DashboardReplacement -SplitOn '_' -BeforeSplit @{ 'One' = 'Report'; 'Two' = 'Report' }
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

    It 'does not write HTML, statistics, manifests, logs, or locks in either preview mode' -TestCases @(@{ Mode = 'TestMode' }, @{ Mode = 'WhatIf' }) {
        param($Mode)
        $Root = Join-Path $TestDrive $Mode
        New-TestReports -Root (Join-Path $Root 'Reports') -Names 'Report_2026-10-02_090000.html'
        $Arguments = @{ Root = $Root }; $Arguments[$Mode] = $true
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
            New-DashboardFolder -Name Reports -UrlName Reports -Path (Join-Path $Root 'Reports') -CopyFrom $Source
        }
        $Result.Files.Count | Should -Be 1
        Test-Path -LiteralPath $Root | Should -BeFalse
    }

    It 'fails on a collector error, unsupported element, or missing report folder before publishing' {
        $Root = Join-Path $TestDrive 'failures'
        New-TestReports -Root $Root -Names 'Index.html', 'Unrelated.html'
        $Before = (Get-FileHash -LiteralPath (Join-Path $Root 'Index.html')).Hash
        { Start-TheDashboard -HTMLPath (Join-Path $Root 'Index.html') { throw 'Collector failed' } } | Should -Throw '*Collector failed*'
        { Start-TheDashboard -HTMLPath (Join-Path $Root 'Index.html') { @{ Type = 'Notification' } } } | Should -Throw '*not supported*'
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
        foreach ($Path in $First.FilePathsGenerated) { Test-Path -LiteralPath $Path -PathType Leaf | Should -BeTrue }
        $HTML = Get-Content -LiteralPath (Join-Path $Root 'Index.html') -Raw
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
            param($Source, $Destination, $Root)
            Publish-DashboardFiles -Files @(@{ Source = $Source; Destination = $Destination }, @{ Source = (Join-Path $Root 'Missing.html'); Destination = (Join-Path $Root 'Other.html') })
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
        try { $null = Start-TheDashboard -HTMLPath (Join-Path $Root 'Index.html') -Online $Elements }
        finally { $ReadLock.Dispose() }
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
