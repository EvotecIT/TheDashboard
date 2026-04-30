function Repair-DashboardContent {
    <#
    .SYNOPSIS
    Replaces content in dashboard files with a specific extension.

    .DESCRIPTION
    Replaces content in dashboard files with a specific extension and keeps a small state file so
    unchanged files that were already checked for the same repair rule can be skipped on later runs.

    .PARAMETER Directory
    Directory where files are located.

    .PARAMETER ExtensionFrom
    File extension to look for. Default is .aspx.

    .PARAMETER StatePath
    Path to the state file used to skip unchanged files that were already checked for this repair rule.

    .PARAMETER NoStateCache
    Disables the state file and scans file content on every run.

    .PARAMETER PassThru
    Returns per-file repair results.

    .EXAMPLE
    $SearchString = "_|:|@|#|<-|<:|<%|=|=>|>:"
    $ReplaceString = "_|:|@|#|<-|<:|<-%|=|=>|>:"
    Repair-DashboardContent -Directory "C:\Reports" -ExtensionFrom ".html" -Search $SearchString -Replace $ReplaceString -EscapeRegex

    .EXAMPLE
    $SearchString = '<meta http-equiv="Content-Security-Policy".*?/>'
    Repair-DashboardContent -Directory "C:\Reports" -ExtensionFrom ".html" -Search $SearchString -Replace ''

    .NOTES
    This is a fix for SharePoint-hosted reports containing server-block-like strings such as "<%"
    and PingCastle reports containing Content-Security-Policy meta tags.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [parameter(Mandatory)][string] $Directory,
        [string] $ExtensionFrom = '.aspx',
        [string] $Search,
        [string] $Replace,
        [switch] $EscapeRegex,
        [int] $OnlyNewerThan,
        [switch] $AddOneMinute,
        [string] $StatePath,
        [switch] $NoStateCache,
        [switch] $PassThru
    )

    if ($EscapeRegex) {
        $SearchString = [regex]::Escape($Search)
        $ReplaceString = $Replace -replace '\$', '$$$$'
    } else {
        $SearchString = $Search
        $ReplaceString = $Replace
    }

    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
        Write-Color -Text '[i]', "[TheDashboard] ", "Directory $Directory does not exist" -Color Yellow, DarkGray, Yellow, DarkGray, Magenta
        return
    }

    $resolvedDirectory = (Resolve-Path -LiteralPath $Directory).Path
    if (-not $StatePath) {
        $StatePath = Join-Path -Path $resolvedDirectory -ChildPath '.thedashboard-repair-content.json'
    }

    $ruleHashInput = [string]::Join([Environment]::NewLine, @(
            $ExtensionFrom.ToLowerInvariant()
            $SearchString
            $ReplaceString
            [string] [bool] $EscapeRegex
        ))
    $ruleHashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($ruleHashInput))
    $ruleHash = -join ($ruleHashBytes | ForEach-Object { $_.ToString('x2') })

    $state = [ordered] @{
        Version = 1
        Rules   = [ordered] @{}
    }
    if (-not $NoStateCache -and (Test-Path -LiteralPath $StatePath)) {
        try {
            $loadedState = Get-Content -LiteralPath $StatePath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            if ($loadedState -and $loadedState.Rules) {
                foreach ($ruleProperty in $loadedState.Rules.PSObject.Properties) {
                    $loadedRule = [ordered] @{}
                    foreach ($fileProperty in $ruleProperty.Value.PSObject.Properties) {
                        $loadedRule[$fileProperty.Name] = $fileProperty.Value
                    }
                    $state.Rules[$ruleProperty.Name] = $loadedRule
                }
            }
        } catch {
            Write-Color -Text '[i]', "[TheDashboard] ", "Ignoring unreadable repair state file $StatePath" -Color Yellow, DarkGray, Yellow
        }
    }
    if (-not $state.Rules.Contains($ruleHash)) {
        $state.Rules[$ruleHash] = [ordered] @{}
    }
    $ruleState = $state.Rules[$ruleHash]
    $stateChanged = $false
    $results = [System.Collections.Generic.List[object]]::new()

    $files = Get-ChildItem -LiteralPath $Directory -File -Recurse -Filter "*$ExtensionFrom"
    foreach ($file in $files) {
        if ($file.Extension -ine $ExtensionFrom) {
            continue
        }

        if ($OnlyNewerThan -and $file.LastWriteTime -lt (Get-Date).AddDays(-$OnlyNewerThan)) {
            if ($PassThru) {
                $results.Add([PSCustomObject] @{
                        FilePath = $file.FullName
                        Status   = 'SkippedOld'
                        Changed  = $false
                    })
            }
            continue
        }

        $relativePath = Get-DashboardRepairRelativePath -BasePath $resolvedDirectory -Path $file.FullName
        $currentFingerprint = [ordered] @{
            LastWriteTimeUtcTicks = $file.LastWriteTimeUtc.Ticks
            Length                = $file.Length
        }
        $cachedFingerprint = if ($ruleState.Contains($relativePath)) { $ruleState[$relativePath] } else { $null }
        if (-not $NoStateCache -and $cachedFingerprint) {
            $sameTimestamp = [int64] $cachedFingerprint.LastWriteTimeUtcTicks -eq [int64] $currentFingerprint.LastWriteTimeUtcTicks
            $sameLength = [int64] $cachedFingerprint.Length -eq [int64] $currentFingerprint.Length
            if ($sameTimestamp -and $sameLength) {
                Write-Verbose "Skipping unchanged repaired file $($file.FullName)"
                if ($PassThru) {
                    $results.Add([PSCustomObject] @{
                            FilePath = $file.FullName
                            Status   = 'SkippedUnchanged'
                            Changed  = $false
                        })
                }
                continue
            }
        }

        if ($PSCmdlet.ShouldProcess($file.FullName, "Repair dashboard content")) {
            Write-Color -Text '[i]', "[TheDashboard] ", "Processing fixes $($file.FullName) / $($file.LastWriteTime)" -Color Yellow, DarkGray, Yellow, DarkGray, Magenta
            $originalCreationTime = $file.CreationTime
            $originalLastWriteTime = $file.LastWriteTime

            $encoding = Get-FileEncoding -Path $file.FullName
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                $fileContent = Get-Content -Raw -LiteralPath $file.FullName -Encoding $encoding
            } else {
                if ($encoding -eq 'UTF8BOM') {
                    $encoding = 'UTF8'
                }
                $fileContent = Get-Content -Raw -LiteralPath $file.FullName -Encoding $encoding
            }

            $changed = $false
            if ($fileContent -match $SearchString) {
                Write-Color -Text '[i]', "[TheDashboard] ", "Processing fixes $($file.FullName) for ($SearchString)" -Color Green
                $newContent = $fileContent -replace $SearchString, $ReplaceString
                $newContent | Set-Content -LiteralPath $file.FullName -Encoding $encoding

                $item = Get-Item -LiteralPath $file.FullName
                $item.CreationTime = $originalCreationTime
                if ($AddOneMinute) {
                    $item.LastWriteTime = $originalLastWriteTime.AddMinutes(1)
                } else {
                    $item.LastWriteTime = $originalLastWriteTime
                }
                $changed = $true
            }

            if (-not $NoStateCache) {
                $item = Get-Item -LiteralPath $file.FullName
                $ruleState[$relativePath] = [ordered] @{
                    LastWriteTimeUtcTicks = $item.LastWriteTimeUtc.Ticks
                    Length                = $item.Length
                }
                $stateChanged = $true
            }

            if ($PassThru) {
                $results.Add([PSCustomObject] @{
                        FilePath = $file.FullName
                        Status   = if ($changed) { 'Repaired' } else { 'CheckedNoMatch' }
                        Changed  = $changed
                    })
            }
        } elseif ($PassThru) {
            $results.Add([PSCustomObject] @{
                    FilePath = $file.FullName
                    Status   = 'WhatIf'
                    Changed  = $false
                })
        }
    }

    if (-not $NoStateCache -and $stateChanged -and -not $WhatIfPreference) {
        $stateDirectory = Split-Path -Path $StatePath -Parent
        if ($stateDirectory -and -not (Test-Path -LiteralPath $stateDirectory)) {
            $null = New-Item -Path $stateDirectory -ItemType Directory -Force
        }
        $state | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $StatePath -Encoding UTF8
    }

    if ($PassThru) {
        $results
    }
}

function Get-DashboardRepairRelativePath {
    param(
        [Parameter(Mandatory)][string] $BasePath,
        [Parameter(Mandatory)][string] $Path
    )

    $baseFullPath = [System.IO.Path]::GetFullPath($BasePath).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $targetFullPath = [System.IO.Path]::GetFullPath($Path)
    $baseUri = [System.Uri]::new($baseFullPath + [System.IO.Path]::DirectorySeparatorChar)
    $targetUri = [System.Uri]::new($targetFullPath)
    return [System.Uri]::UnescapeDataString($baseUri.MakeRelativeUri($targetUri).ToString()).Replace('/', [System.IO.Path]::DirectorySeparatorChar)
}
