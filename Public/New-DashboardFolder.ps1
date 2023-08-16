function New-DashboardFolder {
    [alias('New-TheDashboardFolder')]
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)][scriptblock] $Entries,
        [Parameter(Mandatory)][string] $Name,
        [Parameter(Mandatory)][string] $Path,
        [Parameter(Mandatory)][string] $UrlName,
        [string] $CopyFrom,
        [string] $MoveFrom,
        [switch] $DisableGlobalReplacement,
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
            # if ($E.Type -eq 'Gage') {
            #     $GageConfiguration.Add($E.Settings)
            # } elseif ($E.Type -eq 'Folder') {
            #     $FoldersConfiguration.Add($E.Settings)
            if ($E.Type -eq 'Replacement') {
                $ReplacementConfiguration.Add($E.Settings)
            } elseif ($E.Type -eq 'FolderLimit') {
                $LimitsConfiguration[$E.Settings.Name] = $E.Settings
            }
        }
        $ReplacementsConfiguration = Convert-MultipleReplacements -ReplacementConfiguration $ReplacementConfiguration

    } else {
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
            ReplacementsGlobal  = -not $DisableGlobalReplacement.IsPresent
            Replacements        = $ReplacementsConfiguration
            LimitsConfiguration = $LimitsConfiguration
        }
    }
    Remove-EmptyValue -Hashtable $Folder
    $Folder
}