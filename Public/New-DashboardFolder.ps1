function New-DashboardFolder {
    <#
    .SYNOPSIS
    Defines a report folder displayed as a top-level dashboard menu.

    .DESCRIPTION
    Configures a report folder, optional copy/move sources, naming rules, retention limits,
    and a navigation icon. Without an explicit icon, the menu uses a solid folder icon.
    Nested configuration accepts replacement and retention elements.

    .PARAMETER Entries
    Script block containing New-DashboardReplacement and New-DashboardLimit elements.

    .PARAMETER Name
    Menu label displayed in the dashboard.

    .PARAMETER Path
    Report directory beneath the dashboard output directory. Only top-level files with
    the dashboard page extension create menu entries. Use CopyFrom for external sources.

    .PARAMETER UrlName
    Filename prefix for this menu's generated wrappers. Use a valid filename component
    without path separators; it does not rename the raw report directory.

    .PARAMETER CopyFrom
    Source directories scanned recursively for reports and configured supporting assets.
    Matching files are copied into Path with relative subdirectories preserved.

    .PARAMETER MoveFrom
    Imports matching files into Path and removes each source only after successful
    publication, provided its content still matches the copied destination.

    .PARAMETER Extension
    Additional extensions to copy and deploy, such as '.css', '.js', or '.png'. Supporting
    assets are discovered recursively without creating menu entries. The dashboard page
    extension is included automatically.

    .PARAMETER DisableGlobalReplacement
    Uses this folder's replacement settings instead of global naming rules.

    .PARAMETER DisableGlobalLimits
    Uses only this folder's retention settings instead of applying the global limit.

    .PARAMETER IconBrands
    FontAwesome brand icon for the menu.

    .PARAMETER IconRegular
    FontAwesome regular icon for the menu.

    .PARAMETER IconSolid
    FontAwesome solid icon for the menu. Defaults to 'folder' when no icon is supplied.

    .EXAMPLE
    New-DashboardFolder -Name 'Reports' -UrlName 'Reports' -Path (Join-Path $OutputRoot 'Reports')

    Defines a menu for reports already stored beneath the dashboard output directory.

    .EXAMPLE
    New-DashboardFolder -Name 'Policies' -UrlName 'Policies' -Path (Join-Path $OutputRoot 'Policies') -CopyFrom $SourceRoot -Extension '.css', '.js' {
        New-DashboardReplacement -SplitOn '_' -AfterSplitPositionName 0
        New-DashboardLimit -LimitItem 2 -IncludeHistory
    } -DisableGlobalReplacement

    Imports reports and companion assets, selects a display name, and retains older versions.

    .OUTPUTS
    A folder configuration record consumed by Start-TheDashboard.
    #>
    [alias('New-TheDashboardFolder')]
    [CmdletBinding(DefaultParameterSetName = 'FontAwesomeSolid')]
    param(
        [Parameter(Position = 0)][scriptblock] $Entries,
        [Parameter(Mandatory)][string] $Name,
        [Parameter(Mandatory)][string] $Path,
        [Parameter(Mandatory)][string] $UrlName,
        [string[]] $CopyFrom,
        [string[]] $MoveFrom,
        [string[]] $Extension,
        [switch] $DisableGlobalReplacement,
        [switch] $DisableGlobalLimits,
        # ICON BRANDS
        [ArgumentCompleter(
            {
                param(
                    $CommandName,
                    $ParameterName,
                    $WordToComplete,
                    $CommandAst,
                    $FakeBoundParameters
                )
                ($Global:HTMLIcons.FontAwesomeBrands.Keys)
            }
        )]
        [ValidateScript(
            {
                $_ -in (($Global:HTMLIcons.FontAwesomeBrands.Keys))
            }
        )]
        [parameter(ParameterSetName = "FontAwesomeBrands")][string] $IconBrands,

        # ICON REGULAR
        [ArgumentCompleter(
            {
                param(
                    $CommandName,
                    $ParameterName,
                    $WordToComplete,
                    $CommandAst,
                    $FakeBoundParameters
                )
                ($Global:HTMLIcons.FontAwesomeRegular.Keys)
            }
        )]
        [ValidateScript(
            {
                $_ -in (($Global:HTMLIcons.FontAwesomeRegular.Keys))
            }
        )]
        [parameter(ParameterSetName = "FontAwesomeRegular")][string] $IconRegular,

        # ICON SOLID
        [ArgumentCompleter(
            {
                param(
                    $CommandName,
                    $ParameterName,
                    $WordToComplete,
                    $CommandAst,
                    $FakeBoundParameters
                )
                ($Global:HTMLIcons.FontAwesomeSolid.Keys)
            }
        )]
        [ValidateScript(
            {
                $_ -in (($Global:HTMLIcons.FontAwesomeSolid.Keys))
            }
        )]
        [parameter(ParameterSetName = "FontAwesomeSolid")][string] $IconSolid
    )


    if ($IconBrands) {
        $IconType = 'IconBrands'
        $Icon = $IconBrands
    } elseif ($IconRegular) {
        $IconType = 'IconRegular'
        $Icon = $IconRegular
    } elseif ($IconSolid) {
        $IconType = 'IconSolid'
        $Icon = $IconSolid
    } else {
        $IconType = 'IconSolid'
        $Icon = 'folder'
    }

    if ($Entries) {
        $ReplacementConfiguration = [System.Collections.Generic.List[System.Collections.IDictionary]]::new()
        $LimitsConfiguration = [ordered] @{}
        $OutputElements = & $Entries
        foreach ($E in $OutputElements) {
            if ($E.Type -eq 'Replacement') {
                $ReplacementConfiguration.Add($E.Settings)
            } elseif ($E.Type -eq 'FolderLimit') {
                $LimitsConfiguration[$E.Settings.Name] = $E.Settings
            } elseif ($E.Type) {
                throw "Folder element '$($E.Type)' is not supported. Use replacements or retention limits."
            }
        }
        $ReplacementsConfiguration = Convert-MultipleReplacements -ReplacementConfiguration $ReplacementConfiguration
    } else {
        $LimitsConfiguration = [ordered] @{}
        $ReplacementsConfiguration = $null
    }

    $Folder = [ordered] @{
        Type     = 'Folder'
        Settings = [ordered] @{
            Name                = $Name
            IconType            = $IconType
            Icon                = $Icon
            Path                = $Path
            Url                 = $UrlName
            CopyFrom            = $CopyFrom
            MoveFrom            = $MoveFrom
            Extension           = $Extension
            ReplacementsGlobal  = -not $DisableGlobalReplacement.IsPresent
            Replacements        = $ReplacementsConfiguration
            LimitsConfiguration = $LimitsConfiguration
            DisableGlobalLimits = $DisableGlobalLimits.IsPresent
        }
    }
    Remove-EmptyValue -Hashtable $Folder -Recursive -ExcludeParameter 'LimitsConfiguration', 'Replacements' -DoNotRemoveEmptyDictionary
    $Folder
}
