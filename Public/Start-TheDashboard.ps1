function Start-TheDashboard {
    <#
    .SYNOPSIS
    Generates TheDashboard from multiple provided reports in form of HTML files.

    .DESCRIPTION
    Generates TheDashboard from multiple provided reports in form of HTML files.
    It also generates statistics and charts based on the data provided by additional data.

    .PARAMETER Elements
    ScriptBlock that accepts New-Dashboard* functions, allowing for configuration of TheDashboard.

    .PARAMETER HTMLPath
    Path to HTML files that will be generated.

    .PARAMETER StatisticsPath
    Path to XML file that will save some of the data that is used to generate charts

    .PARAMETER Logo
    Path to logo that will be used in the header.

    .PARAMETER Folders
    Folders that will be used to generate TheDashboard.
    Can co-exist with Elements parameter, and configuration using both will be merged.

    .PARAMETER UrlPath
    URL that will be used as a starting point for TheDashboard, and used by all the links.
    By default the URL uses relative path, but it can be changed to absolute path.
    This is useful for example when you want to use TheDashboard on a SharePoint site, where the files are stored in a different place.

    .PARAMETER Replacements
    Replacements that will be used to replace names within TheDashboard.

    .PARAMETER ShowHTML
    Show TheDashboard in browser after generating it.

    .PARAMETER Online
    Tells Dashboard to use CSS/JS from CDN instead of local files.

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>
    [cmdletBinding()]
    param(
        [Parameter(Position = 0)][ScriptBlock] $Elements,
        [Parameter(Position = 1, Mandatory)][alias('FilePath')][string] $HTMLPath,
        [string] $StatisticsPath,
        [string] $Logo,
        [System.Collections.IDictionary] $Folders,
        [System.Collections.IDictionary] $Replacements,
        [Uri] $UrlPath,
        [switch] $ShowHTML,
        [switch] $Online
    )
    $Script:Reporting = [ordered] @{}
    $Script:Reporting['Version'] = Get-GitHubVersion -Cmdlet 'Start-TheDashboard' -RepositoryOwner 'evotecit' -RepositoryName 'TheDashboard'

    Write-Color '[i]', "[TheDashboard] ", 'Version', ' [Informative] ', $Script:Reporting['Version'] -Color Yellow, DarkGray, Yellow, DarkGray, Magenta

    $TopStats = [ordered] @{}
    if (-not $Folders) {
        $Folders = [ordered] @{}
    }
    $GageConfiguration = [System.Collections.Generic.List[System.Collections.IDictionary]]::new()
    $FoldersConfiguration = [System.Collections.Generic.List[System.Collections.IDictionary]]::new()
    $ReplacementConfiguration = [System.Collections.Generic.List[System.Collections.IDictionary]]::new()
    if ($Elements) {
        $TimeLogElements = Start-TimeLog
        Write-Color -Text '[i]', "[TheDashboard] ", 'Executing nested elements (data gathering/conversions)', ' [Informative] ' -Color Yellow, DarkGray, Yellow, DarkGray, Magenta
        $OutputElements = & $Elements
        foreach ($E in $OutputElements) {
            if ($E.Type -eq 'Gage') {
                $GageConfiguration.Add($E.Settings)
            } elseif ($E.Type -eq 'Folder') {
                $FoldersConfiguration.Add($E.Settings)
            } elseif ($E.Type -eq 'Replacement') {
                $ReplacementConfiguration.Add($E.Settings)
            } elseif ($E.Type -eq 'FolderLimit') {
                $FolderLimit = $E.Settings
            }
        }

        $TimeLogElements = Stop-TimeLog -Time $TimeLogElements -Option OneLiner
        Write-Color -Text '[i]', "[TheDashboard] ", 'Executing nested elements (data gathering/conversions)', ' [Time to execute: ', $TimeLogElements, ']' -Color Yellow, DarkGray, Yellow, DarkGray, Magenta
    }

    if ($StatisticsPath -and (Test-Path -LiteralPath $StatisticsPath)) {
        Write-Color -Text '[i]', "[TheDashboard] ", 'Importing Statistics', ' [Informative] ', $StatisticsPath -Color Yellow, DarkGray, Yellow, DarkGray, Magenta
        $TopStats = Import-Clixml -LiteralPath $StatisticsPath
    }

    $Extension = [io.path]::GetExtension($HTMLPath)
    $FolderPath = [io.path]::GetDirectoryName($HTMLPath)

    foreach ($E in $GageConfiguration) {
        $TopStats[$E.Date] = [ordered] @{}
        $TopStats[$E.Date].Date = $E.Date
    }

    # convert replacements into a single entry
    # this is to make sure user can use different ways of replacing things
    $Replacements = Convert-MultipleReplacements -Replacements $Replacements -ReplacementConfiguration $ReplacementConfiguration

    # build folders configuration
    Set-FolderConfiguration -Folders $Folders -FoldersConfiguration $FoldersConfiguration -FolderLimit $FolderLimit

    # copy or move HTML files to the right place, as user requested
    Copy-HTMLFiles -Folders $Folders -Extension $Extension

    # create menu data information based on files
    $Files = Convert-FilesToMenuData -Folders $Folders -Replacements $Replacements -Extension $Extension

    # Prepare menu based on files
    $MenuBuilder = Convert-FilesToMenu -Files $Files -Folders $Folders

    $FilePathsGenerated = New-HTMLReport -OutputElements $GageConfiguration -Logo $Logo -MenuBuilder $MenuBuilder -Configuration $Configuration -TopStats $TopStats -Files $Files -ShowHTML:$ShowHTML.IsPresent -HTMLPath $HTMLPath -Online:$Online.IsPresent -Force:$Force.IsPresent -Extension $Extension -UrlPath $UrlPath
    Remove-DiscardedReports -FilePathsGenerated $FilePathsGenerated -FolderPath $FolderPath -Extension $Extension

    # Export statistics to file to create charts later on
    if ($StatisticsPath) {
        try {
            $TopStats | Export-Clixml -Depth 3 -LiteralPath $StatisticsPath -ErrorAction Stop
        } catch {
            Write-Color -Text '[e]', "[TheDashboard] ", 'Failed to export statistics', ' [Error] ', $_.Exception.Message -Color Yellow, DarkGray, Yellow, DarkGray, Red
        }
    }
    Write-Color -Text '[i]', "[TheDashboard] ", 'Done', ' [Informative] ' -Color Yellow, DarkGray, Yellow, DarkGray, Magenta
}