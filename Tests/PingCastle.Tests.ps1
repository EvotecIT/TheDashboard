BeforeAll {
    Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'TheDashboard.psd1') -Force -ErrorAction Stop

    function Invoke-PingCastleDashboard {
        <#
        .SYNOPSIS
        Generates the two-domain fixture with the reported replacement and retention settings.

        .PARAMETER Root
        Test-owned output directory containing the PingCastle report folder.

        .PARAMETER PositionRules
        Filename-position rules, including the ordinary hashtable from the reported configuration.
        #>
        param(
            [string] $Root,
            [System.Collections.IDictionary] $PositionRules
        )
        Start-TheDashboard -HTMLPath (Join-Path $Root 'Index.html') -StatisticsPath (Join-Path $Root 'Dashboard.xml') -Online -PassThru {
            New-DashboardFolder -Name 'PingCastle' -IconBrands gofore -UrlName 'PingCastle' -Path (Join-Path $Root 'PingCastle')
            $Replacements = [ordered] @{
                SplitOn                = '[_-]'
                BeforeSplit            = [ordered] @{
                    'Testimo_'         = ''
                    'GPOZaurr_'        = ''
                    'GroupMembership-' = ''
                    '_Regional'        = ' Regional'
                    'ADEssentials_'    = ''
                    'GraphEssentials_' = ''
                }
                AfterSplit             = [ordered] @{
                    'G P O'                    = 'GPO'
                    'L D A P'                  = 'LDAP'
                    'L A P S'                  = 'LAPS'
                    'K R B G T'                = 'KRBGT'
                    'A D'                      = 'AD'
                    'I T R X X'                = 'ITRXX'
                    'I N S'                    = 'INS'
                    'D H C P'                  = 'DHCP'
                    'S P N'                    = 'SPN'
                    'D N S'                    = 'DNS'
                    '0 AD E L'                 = '0ADEL'
                    'K D S'                    = 'KDS'
                    'D C'                      = 'DC'
                    'A C L'                    = 'ACL'
                    'S I D'                    = 'SID'
                    'Bit Locker'               = 'BitLocker'
                    'Windows Update Reporting' = 'Windows Updates'
                }
                AddSpaceToName         = $true
                AfterSplitPositionName = $PositionRules
            }
            New-DashboardReplacement @Replacements
            New-DashboardLimit -LimitItem 7 -IncludeHistory -IncludeHistoryLimitDays 90
        }
    }
}

Describe 'PingCastle repair and dashboard generation together' {
    It 'does not cache a failed write when the caller continues after errors' -Skip:($env:OS -ne 'Windows_NT') {
        $Root = Join-Path $TestDrive 'failed-write'
        $null = [IO.Directory]::CreateDirectory($Root)
        $Report = Join-Path $Root 'Report.html'
        [IO.File]::WriteAllText($Report, 'Original')
        (Get-Item -LiteralPath $Report).IsReadOnly = $true
        $Engine = if ($PSVersionTable.PSEdition -eq 'Desktop') { Join-Path $PSHOME 'powershell.exe' } else { Join-Path $PSHOME 'pwsh.exe' }
        $Driver = Join-Path $PSScriptRoot 'Fixtures/Invoke-ReadOnlyRepair.ps1'
        $ModuleManifest = Join-Path (Split-Path $PSScriptRoot -Parent) 'TheDashboard.psd1'
        $SharedGoodsManifest = (Get-Module PSSharedGoods | Select-Object -First 1).Path
        $WriteHTMLManifest = (Get-Module PSWriteHTML | Select-Object -First 1).Path
        $WriteColorManifest = (Get-Module PSWriteColor | Select-Object -First 1).Path
        $PSNativeCommandUseErrorActionPreference = $false
        $PreviousErrorActionPreference = $ErrorActionPreference
        try {
            # Windows PowerShell wraps native stderr as error records, including the expected failure.
            $ErrorActionPreference = 'Continue'
            & $Engine -NoProfile -File $Driver -ModuleManifest $ModuleManifest -ReportRoot $Root -SharedGoodsManifest $SharedGoodsManifest -WriteHTMLManifest $WriteHTMLManifest -WriteColorManifest $WriteColorManifest *> (Join-Path $Root 'child.log')
            $RepairExitCode = $LASTEXITCODE
            $ErrorActionPreference = $PreviousErrorActionPreference
            $RepairExitCode | Should -Be 1
            [IO.File]::ReadAllText((Join-Path $Root 'child.log')) | Should -Match 'READY_TO_REPAIR'
            Test-Path -LiteralPath (Join-Path $Root '.thedashboard-repair-content.json') | Should -BeFalse
            [IO.File]::ReadAllText($Report) | Should -Be 'Original'
        } finally {
            $ErrorActionPreference = $PreviousErrorActionPreference
            (Get-Item -LiteralPath $Report).IsReadOnly = $false
        }
        $Retry = @(Repair-DashboardContent -Directory $Root -ExtensionFrom '.html' -Search 'Original' -Replace 'Repaired' -PassThru)
        $Retry.Count | Should -Be 1
        $Retry[0].Status | Should -Be 'Repaired'
        [IO.File]::ReadAllText($Report).Trim() | Should -Be 'Repaired'
    }

    It 'keeps both domains and their navigation through repair, retention and cached generation with <Case> rules' -ForEach @(
        @{
            Case  = 'the reported ordinary hashtable'
            Rules = @{
                '*PingCastle*'    = 1, 2
                '*WindowsUpdate*' = 0
                '*'               = 0
            }
        },
        @{
            Case  = 'fallback-first ordered'
            Rules = [ordered] @{
                '*'               = 0
                '*WindowsUpdate*' = 0
                '*PingCastle*'    = 1, 2
            }
        }
    ) {
        $Root = Join-Path $TestDrive (($Case -replace '[^a-zA-Z]', '') + 'Dashboard')
        $ReportRoot = Join-Path $Root 'PingCastle'
        $null = [IO.Directory]::CreateDirectory($ReportRoot)
        $Today = (Get-Date).Date
        foreach ($Domain in 'example.test', 'group.example.test') {
            foreach ($Week in 0..8) {
                $Date = $Today.AddDays(-7 * $Week).AddHours(1)
                $Stamp = $Date.ToString('yyyy-MM-dd_HHmmss')
                $Path = Join-Path $ReportRoot "PingCastle-Domain-${Domain}_$Stamp.html"
                [IO.File]::WriteAllText($Path, '<html><head><meta http-equiv="Content-Security-Policy" content="default-src none" /></head><body>Synthetic report</body></html>')
                [IO.File]::SetLastWriteTime($Path, $Date)
            }
        }
        $Repair = @{
            Directory     = $ReportRoot
            ExtensionFrom = '.html'
            Search        = '<meta http-equiv="Content-Security-Policy".*?/>'
            Replace       = ''
            AddOneMinute  = $true
            PassThru      = $true
        }
        $FirstRepair = @(Repair-DashboardContent @Repair)
        $FirstRepair.Count | Should -Be 18
        @($FirstRepair | Where-Object Status -eq Repaired).Count | Should -Be 18
        $CachedRepair = @(Repair-DashboardContent @Repair)
        @($CachedRepair | Where-Object Status -eq SkippedUnchanged).Count | Should -Be 18

        $First = Invoke-PingCastleDashboard -Root $Root -PositionRules $Rules
        $First.MenuBuilder.PingCastle.Count | Should -Be 2
        foreach ($Domain in 'example.test', 'group.example.test') {
            $Group = $First.MenuBuilder.PingCastle["pingcastle-domain-$Domain"]
            $Group.Current.Name | Should -Be "Domain $Domain"
            $Group.Current.Date | Should -Be $Today.AddHours(1)
            $Group.Full.Count | Should -Be 7
            $Group.History.Count | Should -Be 2
            @($Group.Full + $Group.History | Where-Object { $_.Domain -ne $Domain }).Count | Should -Be 0
            [IO.File]::ReadAllText($Group.Current.FullPath) | Should -Not -Match 'Content-Security-Policy'
        }
        $First.FilePathsGenerated.Count | Should -Be 17
        foreach ($Page in $First.FilePathsGenerated) {
            $Html = [IO.File]::ReadAllText($Page)
            $Menus = [regex]::Matches($Html, '(?s)<ul class="menu-items"[^>]*>(.*?)</ul>')
            $Menus.Count | Should -Be 1
            [regex]::Matches($Menus[0].Groups[1].Value, '<a\s').Count | Should -Be 2
            foreach ($Domain in 'example.test', 'group.example.test') {
                $PageName = $First.MenuBuilder.PingCastle["pingcastle-domain-$Domain"].Current.PageName
                $Menus[0].Value.Contains("href=`"$PageName`"") | Should -BeTrue
                $Menus[0].Value | Should -Match ([regex]::Escape(">Domain $Domain</a>"))
            }
        }
        $Cached = Invoke-PingCastleDashboard -Root $Root -PositionRules $Rules
        @($Cached.MenuBuilder.PingCastle.Values.Current | Where-Object SkipGeneration).Count | Should -Be 2

        $ParentReport = $Cached.MenuBuilder.PingCastle['pingcastle-domain-example.test'].Current.FullPath
        [IO.File]::WriteAllText($ParentReport, '<html><head><meta http-equiv="Content-Security-Policy" content="default-src none" /></head><body>Updated synthetic report</body></html>')
        $UpdatedRepair = @(Repair-DashboardContent @Repair)
        @($UpdatedRepair | Where-Object Status -eq Repaired).Count | Should -Be 1
        @($UpdatedRepair | Where-Object Status -eq SkippedUnchanged).Count | Should -Be 17
        $Updated = Invoke-PingCastleDashboard -Root $Root -PositionRules $Rules
        $Updated.MenuBuilder.PingCastle.Count | Should -Be 2
        $Updated.MenuBuilder.PingCastle['pingcastle-domain-example.test'].Current.SkipGeneration | Should -BeFalse
        $Updated.MenuBuilder.PingCastle['pingcastle-domain-group.example.test'].Current.SkipGeneration | Should -BeTrue
    }
}
