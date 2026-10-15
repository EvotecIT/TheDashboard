function Start-TheDashboard {
    <#
    .SYNOPSIS
    Generates a static dashboard from report files and optional gauge data.

    .DESCRIPTION
    Discovers configured report folders, applies naming and retention rules, and renders
    navigation, report wrappers, statistics, and calendars. Original filenames define
    report identity independently of display labels. Generated pages and saved state
    are staged before publication; cleanup removes only previously owned obsolete pages.
    Raw input copies are outside generated-page rollback. Publication is atomic per file
    rather than a whole-site transaction.

    .PARAMETER Elements
    Configuration block containing folders, naming rules, retention limits, gauges, and
    custom report collectors. Collector errors stop generation. Email and notification
    configuration elements are unsupported.

    .PARAMETER HTMLPath
    Landing-page path, including the extension used for report discovery and wrappers.
    Report folders must be beneath its directory. Use CopyFrom or MoveFrom for external inputs.

    .PARAMETER StatisticsPath
    Optional CLIXML file containing statistics and generation fingerprints. Existing
    state is read before rendering and updated after successful generation.

    .PARAMETER Logo
    Logo source passed to the dashboard navigation component.

    .PARAMETER LogoLink
    Destination of the logo link when supplied.

    .PARAMETER LogoLinkHome
    Links the logo to the dashboard home page.

    .PARAMETER Folders
    Dictionary of report-folder definitions. Can be combined with New-DashboardFolder elements.

    .PARAMETER UrlPath
    Optional URL prefix for navigation links, for example when hosting in a site library.
    Without it, generated navigation uses relative links.

    .PARAMETER Replacements
    Global display-name configuration. Can be combined with New-DashboardReplacement elements.

    .PARAMETER RemoveNotIncluded
    Removes raw reports excluded by every section's retention settings. Supporting assets
    and reports retained by another section are preserved.

    .PARAMETER DeleteMethod
    Method used to remove excluded raw reports: RemoveItem, DotNetDelete, or RecycleBin.
    Defaults to RecycleBin. Obsolete generated-page cleanup uses the ownership manifest.

    .PARAMETER TestMode
    Plans generation without writing pages, copied reports, statistics, ownership state,
    locks, or logs. Configuration blocks still execute under WhatIfPreference; custom
    collectors must respect that preference. Use PassThru to inspect the plan.

    .PARAMETER ShowHTML
    Opens the published landing page in the default browser after successful generation.

    .PARAMETER Online
    Uses CDN-hosted PSWriteHTML resources instead of embedding them in generated pages.

    .PARAMETER PassThru
    Returns planning and deployment data, including MenuBuilder, FilesToKeepOrRemove,
    FilePathsGenerated, and Preview. MenuBuilder groups are keyed by report identity.

    .PARAMETER LogPath
    Optional log-file path. Preview suppresses logging writes.

    .PARAMETER LogMaximum
    Maximum number of log files retained. Zero means unlimited. Use a dedicated log
    directory; cleanup is disabled when the log directory contains the calling script.

    .PARAMETER LogShowTime
    Includes timestamps in console logging. File logging includes timestamps by default.

    .PARAMETER LogTimeFormat
    Timestamp format used by the logging helper. The default is 'yyyy-MM-dd HH:mm:ss'.

    .PARAMETER Force
    Regenerates child pages even when their saved generation fingerprints are unchanged.

    .PARAMETER CheckForUpdates
    Checks GitHub for a newer module version. Normal generation does not require this
    network request, and preview skips it.

    .EXAMPLE
    Start-TheDashboard -HTMLPath (Join-Path $OutputRoot 'Index.html') {
        New-DashboardFolder -Name 'Reports' -UrlName 'Reports' -Path (Join-Path $OutputRoot 'Reports')
        New-DashboardLimit -LimitItem 2 -IncludeHistory
    }

    Generates a dashboard from reports already stored in the Reports subdirectory.

    .EXAMPLE
    $Plan = Start-TheDashboard -HTMLPath (Join-Path $OutputRoot 'Index.html') -TestMode -PassThru {
        New-DashboardFolder -Name 'Reports' -UrlName 'Reports' -Path (Join-Path $OutputRoot 'Reports') -CopyFrom $SourceRoot
    }
    $Plan.FilesToKeepOrRemove

    Inspects planned report copies and deployment files without writing them.

    .OUTPUTS
    No output by default. With PassThru, an ordered dictionary describing the generation.
    #>
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0)][ScriptBlock] $Elements,
        [Parameter(Position = 1, Mandatory)][alias('FilePath')][string] $HTMLPath,
        [string] $StatisticsPath,
        [string] $Logo,
        [string] $LogoLink,
        [switch] $LogoLinkHome,
        [System.Collections.IDictionary] $Folders,
        [System.Collections.IDictionary] $Replacements,
        [switch] $RemoveNotIncluded,
        [ValidateSet("RemoveItem", "DotNetDelete", "RecycleBin")]
        [string] $DeleteMethod = "RecycleBin",
        [Uri] $UrlPath,
        [switch] $ShowHTML,
        [switch] $Online,
        [switch] $PassThru,
        [switch] $TestMode,
        [string] $LogPath,
        [int] $LogMaximum,
        [switch] $LogShowTime,
        [string] $LogTimeFormat,
        [switch] $Force,
        [switch] $CheckForUpdates
    )
    $Script:Reporting = [ordered] @{}
    $Preview = $TestMode.IsPresent -or $WhatIfPreference
    $ErrorActionPreference = 'Stop'
    $HTMLPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($HTMLPath)
    $FolderPath = [IO.Path]::GetDirectoryName($HTMLPath)
    $Extension = [IO.Path]::GetExtension($HTMLPath)
    if (-not $Extension) {
        throw 'HTMLPath must include a file extension.'
    }
    if ($StatisticsPath) {
        $StatisticsPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($StatisticsPath)
    }
    if (-not $Preview -and -not $PSCmdlet.ShouldProcess($HTMLPath, 'Generate and publish dashboard')) {
        $Preview = $true
    }
    # Keep logging defaults local, including in merged modules where a previous run may have set them.
    $LoggingDefaults = @{}
    foreach ($Key in $PSDefaultParameterValues.Keys) {
        $LoggingDefaults[$Key] = $PSDefaultParameterValues[$Key]
    }
    $LoggingDefaults['Write-Color:LogFile'] = $null
    $PSDefaultParameterValues = $LoggingDefaults
    $Script:Reporting['Version'] = (Get-Command Start-TheDashboard).Version
    if ($CheckForUpdates -and -not $Preview) {
        $Script:Reporting['Version'] = Get-GitHubVersion -Cmdlet 'Start-TheDashboard' -RepositoryOwner 'evotecit' -RepositoryName 'TheDashboard'
    }
    if (-not $Preview) {
        Set-LoggingCapabilities -LogPath $LogPath -LogMaximum $LogMaximum -ShowTime:$LogShowTime -TimeFormat $LogTimeFormat -ScriptPath $MyInvocation.ScriptName -ParameterPSDefaultParameterValues $PSDefaultParameterValues
    }

    Write-Color '[i]', "[TheDashboard] ", 'Version', ' [Informative] ', $Script:Reporting['Version'] -Color Yellow, DarkGray, Yellow, DarkGray, Magenta

    if ($Preview) {
        Write-Color -Text '[i]', "[TheDashboard] ", 'TestMode enabled', ' [Informative] ' -Color Yellow, DarkGray, Yellow, DarkGray, Magenta
        $WhatIfPreference = $true
    }
    if (-not $Folders) {
        $Folders = [ordered] @{}
    }
    $GageConfiguration = [System.Collections.Generic.List[System.Collections.IDictionary]]::new()
    $FoldersConfiguration = [System.Collections.Generic.List[System.Collections.IDictionary]]::new()
    $ReplacementConfiguration = [System.Collections.Generic.List[System.Collections.IDictionary]]::new()
    $FolderLimit = [ordered] @{}

    $convertNestedElementsSplat = @{
        Elements                 = $Elements
        GageConfiguration        = $GageConfiguration
        FoldersConfiguration     = $FoldersConfiguration
        ReplacementConfiguration = $ReplacementConfiguration
        FolderLimit              = $FolderLimit
    }

    Convert-NestedElements @convertNestedElementsSplat

    # convert replacements into a single entry
    # this is to make sure user can use different ways of replacing things
    $Replacements = Convert-MultipleReplacements -Replacements $Replacements -ReplacementConfiguration $ReplacementConfiguration

    # build folders configuration
    Set-FolderConfiguration -Folders $Folders -FoldersConfiguration $FoldersConfiguration -FolderLimit $FolderLimit

    $CopyPlan = @(Get-DashboardCopyPlan -Folders $Folders -Extension $Extension -OutputRoot $FolderPath)
    $Lock = $null
    $Stage = $null
    try {
        if (-not $Preview) {
            $null = [IO.Directory]::CreateDirectory($FolderPath)
            $Lock = [IO.FileStream]::new($HTMLPath + '.lock', [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None, 4096, [IO.FileOptions]::DeleteOnClose)
        }
        $ExportData = Import-DashboardStatistics -StatisticsPath $StatisticsPath -GageConfiguration $GageConfiguration
        $ManifestPath = Join-Path $FolderPath ('.' + [IO.Path]::GetFileName($HTMLPath) + '.dashboard-manifest.clixml')
        $OwnedFiles = @()
        if (Test-Path -LiteralPath $ManifestPath -PathType Leaf) {
            $Manifest = Import-Clixml -LiteralPath $ManifestPath -ErrorAction Stop
            if ($Manifest.Schema -ne 1) {
                throw 'Unsupported dashboard ownership manifest.'
            }
            $OwnedFiles = @($Manifest.Files)
            foreach ($Owned in $OwnedFiles) {
                if (-not $Owned -or [IO.Path]::GetFileName($Owned) -ne $Owned -or $Owned -in @('.', '..')) {
                    throw "Invalid owned dashboard filename '$Owned'."
                }
            }
        }
        if (-not $Preview) {
            Copy-HTMLFiles -Plan $CopyPlan -Confirm:$false
        }
        $Files = @(Convert-FilesToMenuData -Folders $Folders -Replacements $Replacements -Extension $Extension -OutputRoot $FolderPath -CopyPlan $CopyPlan -Pretend:$Preview)
        $SupportingFiles = @(Get-DashboardSupportingFiles -Folders $Folders -Extension $Extension -CopyPlan $CopyPlan -Pretend:$Preview)
        $MenuBuilder = Convert-FilesToMenu -Files $Files -Folders $Folders
        $Configuration = [ordered] @{
            Folders      = $Folders
            Logo         = $Logo
            LogoLink     = $LogoLink
            LogoLinkHome = $LogoLinkHome.IsPresent
            Online       = $Online.IsPresent
            # Serialize the URL text rather than the Uri object's implementation properties.
            UrlPath      = [string] $UrlPath
        }
        $FilePathsGenerated = @(Set-DashboardPagePlan -MenuBuilder $MenuBuilder -Configuration $Configuration -ExportData $ExportData -HTMLPath $HTMLPath -Force:$Force)
        if ($StatisticsPath -and $StatisticsPath -in $FilePathsGenerated) {
            throw 'StatisticsPath must not overwrite a dashboard page.'
        }
        $ExportData['MenuBuilder'] = $MenuBuilder
        if (-not $Preview) {
            $Stage = Join-Path $FolderPath ('.dashboard-stage-' + [guid]::NewGuid().ToString('N'))
            $null = [IO.Directory]::CreateDirectory($Stage)
            $Render = @{
                OutputElements = $GageConfiguration
                Logo           = $Logo
                LogoLink       = $LogoLink
                LogoLinkHome   = $LogoLinkHome
                MenuBuilder    = $MenuBuilder
                Configuration  = $Configuration
                ExportData     = $ExportData
                Files          = $Files
                HTMLPath       = (Join-Path $Stage ([IO.Path]::GetFileName($HTMLPath)))
                Online         = $Online
                Extension      = $Extension
                UrlPath        = $UrlPath
            }
            $null = New-HTMLReport @Render
            $Publication = [System.Collections.Generic.List[object]]::new()
            $RequiredWrites = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
            foreach ($Menu in $MenuBuilder.Keys) {
                foreach ($Group in $MenuBuilder[$Menu].Values) {
                    if (-not $Group.Current.SkipGeneration) {
                        $null = $RequiredWrites.Add($Group.Current.PageName)
                    }
                    foreach ($Entry in $Group.Full) {
                        if (-not $Entry.SkipSnapshotGeneration) {
                            $null = $RequiredWrites.Add($Entry.FileName)
                        }
                    }
                }
            }
            # Publish the landing page after its children. An exception rolls back pages and state.
            foreach ($Path in $FilePathsGenerated | Where-Object { $_ -ne $HTMLPath }) {
                $StagedPath = Join-Path $Stage ([IO.Path]::GetFileName($Path))
                if (Test-Path -LiteralPath $StagedPath -PathType Leaf) {
                    $Publication.Add(@{
                            Source      = $StagedPath
                            Destination = $Path
                        })
                } elseif ($RequiredWrites.Contains([IO.Path]::GetFileName($Path)) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) {
                    throw "The renderer did not produce '$Path'."
                }
            }
            $Publication.Add(@{
                    Source      = (Join-Path $Stage ([IO.Path]::GetFileName($HTMLPath)))
                    Destination = $HTMLPath
                })
            if ($StatisticsPath) {
                $StatePath = Join-Path $Stage 'statistics.clixml'
                $ExportData | Export-Clixml -Depth 12 -LiteralPath $StatePath -ErrorAction Stop
                $Publication.Add(@{
                        Source      = $StatePath
                        Destination = $StatisticsPath
                    })
            }
            $NewOwnedFiles = @($FilePathsGenerated | ForEach-Object { [IO.Path]::GetFileName($_) })
            $StagedManifest = Join-Path $Stage 'manifest.clixml'
            # Retain old ownership until cleanup succeeds, allowing an interrupted cleanup to retry.
            @{
                Schema = 1
                Files  = @($OwnedFiles + $NewOwnedFiles | Sort-Object -Unique)
            } | Export-Clixml -LiteralPath $StagedManifest -ErrorAction Stop
            $Publication.Add(@{
                    Source      = $StagedManifest
                    Destination = $ManifestPath
                })
            Publish-DashboardFiles -Files $Publication
            Remove-DiscardedReports -FilePathsGenerated $FilePathsGenerated -FolderPath $FolderPath -OwnedFiles $OwnedFiles -Confirm:$false
            @{
                Schema = 1
                Files  = $NewOwnedFiles
            } | Export-Clixml -LiteralPath $StagedManifest -ErrorAction Stop
            Publish-DashboardFiles -Files @(
                @{
                    Source      = $StagedManifest
                    Destination = $ManifestPath
                }
            )
            foreach ($Copy in $CopyPlan | Where-Object Move) {
                if ((Get-FileHash -LiteralPath $Copy.Source).Hash -ne (Get-FileHash -LiteralPath $Copy.Destination).Hash) {
                    throw "Move source '$($Copy.Source)' changed during generation and was preserved. Run generation again after the report writer finishes."
                }
                Remove-Item -LiteralPath $Copy.Source -ErrorAction Stop
            }
        }
        $FilesToKeepOrRemove = Convert-FilesToKeepOrRemove -FilePathsGenerated $FilePathsGenerated -Files $Files -SupportingFiles $SupportingFiles -DeleteMethod $DeleteMethod -RemoveNotIncluded:$RemoveNotIncluded -WhatIf:$Preview
        if ($ShowHTML -and -not $Preview) {
            Start-Process -FilePath $HTMLPath
        }
        if ($PassThru) {
            [ordered] @{
                FilesToKeepOrRemove = $FilesToKeepOrRemove
                Folders             = $Folders
                Extension           = $Extension
                Files               = $Files
                MenuBuilder         = $MenuBuilder
                Statistics          = $ExportData.Statistics
                StatisticsPath      = $StatisticsPath
                Replacements        = $Replacements
                FilePathsGenerated  = $FilePathsGenerated
                Preview             = $Preview
                ManifestPath        = $ManifestPath
            }
        }
    } finally {
        try {
            if ($Stage -and (Test-Path -LiteralPath $Stage)) {
                $StageInfo = Get-Item -LiteralPath $Stage -Force
                $ExpectedRoot = $FolderPath.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
                if (-not $StageInfo.FullName.StartsWith($ExpectedRoot, [StringComparison]::OrdinalIgnoreCase) -or $StageInfo.Name -notlike '.dashboard-stage-*' -or ($StageInfo.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
                    throw "Refusing to clean unexpected staging path '$Stage'."
                }
                Remove-Item -LiteralPath $Stage -Recurse -ErrorAction Stop
            }
        } finally {
            if ($Lock) {
                $Lock.Dispose()
            }
        }
    }
    Write-Color -Text '[i]', "[TheDashboard] ", 'Done', ' [Informative] ' -Color Yellow, DarkGray, Yellow, DarkGray, Magenta
}
