function New-DashboardFolder {
    <#
    .SYNOPSIS
        This function is used to define a new folder for the dashboard that will be displayed as a TopLevelMenu.

    .DESCRIPTION
    This function is used to define a new folder for the dashboard that will be displayed as a TopLevelMenu.
    It allows you to define the folder name, path, and URL name. You can also specify the icon that will be used for the folder.

    .PARAMETER Entries
    This parameter allows you to define the content of the folder. It should be a script block that contains the content of the folder.
    The content of the folder can be defined using the New-DashboardReplacement, New-DashboardLimit functions

    .PARAMETER Name
    The name of the folder that will be displayed in the dashboard.

    .PARAMETER Path
    Path to Reports folder where the reports are stored.

    .PARAMETER UrlName
    The URL name for the dashboard folder. This is used to create the URL for the folder.

    .PARAMETER CopyFrom
    Copy files from this location to the existing location that is specified by the Path parameter.
    This is useful for copying reports from different locations to the expected location.

    .PARAMETER MoveFrom
    Move files from this location to the existing location that is specified by the Path parameter.
    This is useful for moving reports from different locations to the expected location.

    .PARAMETER Extension
    This parameter specifies the file extensions to include when processing files.
    It will by default use the same extension as the root of the dashboard, but this one can include additional extensions.

    .PARAMETER DisableGlobalReplacement
    This parameter, when set, will disable global replacements for the dashboard for this particular folder.
    This means that the replacements defined in the root of the dashboard will not be applied to the content of this folder.

    .PARAMETER DisableGlobalLimits
    This parameter, when set, will disable global limits for the dashboard for this particular folder.
    This means that the limits defined in the root of the dashboard will not be applied to the content of this folder.

    .PARAMETER IconBrands
    Specifies the icon that will be used for the folder. This is a brand icon from FontAwesome.

    .PARAMETER IconRegular
    Specifies the icon that will be used for the folder. This is a regular icon from FontAwesome.

    .PARAMETER IconSolid
    Specifies the icon that will be used for the folder. This is a solid icon from FontAwesome.

    .EXAMPLE
    New-DashboardFolder -Name 'Group Policies' -IconBrands android -UrlName 'GPO' -Path $PSScriptRoot\Reports\TestPolicies

    .EXAMPLE
     New-DashboardFolder -Name 'Windows Updates' -IconBrands android -UrlName 'WindowsUpdates' -Path $PSScriptRoot\Reports\WindowsUpdates {
        $newDashboardReplacementSplat = @{
            BeforeSplit             = @{
                'GroupMembership-' = ''
                '_Regional'        = ' Regional'
                'GPOZaurr'         = ''
                'Testimo'          = ''
            }
            #AfterSplitPositionName  = 1, 2
            AfterSplitPositionName  = [ordered] @{
                'PingCastle-Domain-*' = 0, 2
                '*'                   = 0
                # '*'              = 1, 2
            }
            AfterRemoveDoubleSpaces = $true
            AfterUpperChars         = "evotec.com", "test.com"
            AfterSplit              = @{
                'G P O'     = 'GPO'
                'L D A P'   = 'LDAP'
                'D H C P'   = 'DHCP'
                'A D'       = 'AD'
                'I T R X X' = 'ITRXX'
                'I N S'     = 'INS'
                'L A P S'   = 'LAPS'
                'K R B G T' = 'KRBGT'
            }
            SplitOn                 = "[_-]"
            AddSpaceToName          = $true
        }
        New-DashboardReplacement @newDashboardReplacementSplat
        New-DashboardLimit -LimitItem 2 -IncludeHistory
    } -DisableGlobalReplacement

    .NOTES
    General notes
    #>
    [alias('New-TheDashboardFolder')]
    [CmdletBinding()]
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
                param($CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters)
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
                param($CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters)
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
                param($CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters)
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
    Remove-EmptyValue -Hashtable $Folder -Recursive
    $Folder
}