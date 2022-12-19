function Start-TheDashboard {
    <#
    .SYNOPSIS
    Generates TheDashboard from multiple provided reports in form of HTML files.

    .DESCRIPTION
    Generates TheDashboard from multiple provided reports in form of HTML files.

    .PARAMETER Elements
    Parameter description

    .PARAMETER HTMLPath
    Path to HTML files that will be generated.

    .PARAMETER ExcelPath
    Parameter description

    .PARAMETER StatisticsPath
    Parameter description

    .PARAMETER Logo
    Parameter description

    .PARAMETER Folders
    Parameter description

    .PARAMETER Replacements
    Parameter description

    .PARAMETER ShowHTML
    Show TheDashboard in browser after generating it.

    .PARAMETER Online
    Tells Dashboard to use CSS/JS from CDN instead of local files.

    .PARAMETER Force
    By default dashboard generates HTML files once, and then refreshes only main file from each category leaving the rest as is if it exists.
    This saves a lot of time when generating historical reports. If you want to force regeneration of all files, use this parameter.

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>
    [cmdletBinding()]
    param(
        [ScriptBlock] $Elements,
        [string] $HTMLPath,
        [string] $ExcelPath,
        [string] $StatisticsPath,
        #[parameter(Mandatory)][ValidateSet('ServiceAccounts', 'UsersPasswordNeverExpire', 'ComputersLimitedINS')][string[]] $Type,
        [string] $Logo,
        [System.Collections.IDictionary] $Folders,
        [System.Collections.IDictionary] $Replacements,
        [switch] $ShowHTML,
        [switch] $Online,
        [switch] $Force
    )
    $Script:Reporting = @{}
    $Script:Reporting['Version'] = Get-GitHubVersion -Cmdlet 'Start-TheDashboard' -RepositoryOwner 'evotecit' -RepositoryName 'TheDashboard'

    Write-Color '[i]', "[TheDashboard] ", 'Version', ' [Informative] ', $Script:Reporting['Version'] -Color Yellow, DarkGray, Yellow, DarkGray, Magenta

    $TopStats = [ordered] @{}
    $Cache = @{}

    $ComputerEnabled = 0
    $ComputerDisabled = 0
    $UserDisabled = 0
    $UserEnabled = 0
    foreach ($Computer in $AllComputers) {
        if ($Computer.Enabled) {
            $ComputerEnabled++
        } else {
            $ComputerDisabled++
        }
    }
    foreach ($Computer in $AllUsers) {
        if ($User.Disabled) {
            $UserEnabled++
        } else {
            $UserDisabled++
        }
    }


    foreach ($U in $AllUsers) {
        $Cache[$U.DistinguishedName] = $U
    }
    foreach ($C in $AllComputers) {
        $Cache[$C.DistinguishedName] = $C
    }

    if ($StatisticsPath -and (Test-Path -LiteralPath $StatisticsPath)) {
        Write-Color -Text '[i]', "[TheDashboard] ", 'Importing Statistics', ' [Informative] ', $StatisticsPath -Color Yellow, DarkGray, Yellow, DarkGray, Magenta
        $TopStats = Import-Clixml -LiteralPath $StatisticsPath
    }

    if ($Elements) {
        $TimeLogElements = Start-TimeLog
        Write-Color -Text '[i]', "[TheDashboard] ", 'Executing nested elements', ' [Informative] ' -Color Yellow, DarkGray, Yellow, DarkGray, Magenta
        $OutputElements = & $Elements
        $TimeLogElements = Stop-TimeLog -Time $TimeLogElements -Option OneLiner
        Write-Color -Text '[i]', "[TheDashboard] ", 'Executing nested elements', ' [Time to execute: ', $TimeLogElements, ']' -Color Yellow, DarkGray, Yellow, DarkGray, Magenta

    }
    foreach ($E in $OutputElements) {
        $TopStats[$E.Date] = [ordered] @{}
        $TopStats[$E.Date].Date = $E.Date
    }

    Write-Color -Text '[i]', "[TheDashboard] ", 'Copying or HTML files', ' [Informative] ', $HTMLPath -Color Yellow, DarkGray, Yellow, DarkGray, Magenta
    foreach ($FolderName in $Folders.Keys) {
        if ($Folders[$FolderName].CopyFrom) {
            foreach ($Path in $Folders[$FolderName].CopyFrom) {
                foreach ($File in Get-ChildItem -LiteralPath $Path -Filter "*.html" -Recurse) {
                    $Destination = $File.FullName.Replace($Path, $Folders[$FolderName].Path)
                    $DIrectoryName = [io.path]::GetDirectoryName($Destination)
                    $null = New-Item -Path $DIrectoryName -ItemType Directory -Force
                    Copy-Item -LiteralPath $File.FullName -Destination $Destination -Force -ErrorAction Stop
                }
            }
        } elseif ($Folders[$FolderName].MoveFrom) {
            foreach ($Path in $Folders[$FolderName].MoveFrom) {
                foreach ($File in Get-ChildItem -LiteralPath $Path -Filter "*.html" -Recurse) {
                    $Destination = $File.FullName.Replace($Path, $Folders[$FolderName].Path)
                    $DIrectoryName = [io.path]::GetDirectoryName($Destination)
                    $null = New-Item -Path $DIrectoryName -ItemType Directory -Force
                    Move-Item -LiteralPath $File.FullName -Destination $Destination -Force -ErrorAction Stop
                }
            }
        }
    }

    # create menu information based on files
    Write-Color -Text '[i]', "[TheDashboard] ", 'Creating Menu', ' [Informative] ', $HTMLPath -Color Yellow, DarkGray, Yellow, DarkGray, Magenta
    $Files = foreach ($FolderName in $Folders.Keys) {

        $Folder = $Folders[$FolderName]
        $FilesInFolder = Get-ChildItem -LiteralPath $Folders[$FolderName].Path -ErrorAction SilentlyContinue -Filter *.html | Sort-Object -Property Name
        foreach ($File in $FilesInFolder) {
            $Href = "$($Folders[$FolderName].Url)/$($File.Name)"

            $MenuName = $File.BaseName
            if ($Folder.ReplacementsGlobal -eq $true) {
                foreach ($Replace in $Replacements.BeforeSplit.Keys) {
                    $MenuName = $MenuName.Replace($Replace, $Replacements.BeforeSplit[$Replace])
                }
                $Splitted = $MenuName -split $Replacements.SplitOn
                if ($Replacements.AddSpaceToName) {
                    $Name = Format-AddSpaceToSentence -Text $Splitted[0]
                } else {
                    $Name = $Splitted[0]
                }
                foreach ($Replace in $Replacements.AfterSplit.Keys) {
                    $Name = $Name.Replace($Replace, $Replacements.AfterSplit[$Replace])
                }
            } else {
                foreach ($Replace in $Folder.Replacements.BeforeSplit.Keys) {
                    $MenuName = $MenuName.Replace($Replace, $Folder.Replacements.BeforeSplit[$Replace])
                }
                $Splitted = $MenuName -split $Folder.Replacements.SplitOn
                if ($Folder.Replacements.AddSpaceToName) {
                    $Name = Format-AddSpaceToSentence -Text $Splitted[0]
                } else {
                    $Name = $Splitted[0]
                }
                foreach ($Replace in $Folder.Replacements.AfterSplit.Keys) {
                    $Name = $Name.Replace($Replace, $Folder.Replacements.AfterSplit[$Replace])
                }
            }
            if ($Name -and $Splitted[1]) {
                [ordered] @{
                    Name     = $Name
                    NameDate = $Splitted[1]
                    Href     = $Href
                    FileName = $File.Name
                    Menu     = $FolderName
                    Date     = $File.LastWriteTime
                }
            } else {
                Write-Color -Text "Couldn't create menu item for $($File.FullName)" -Color Red
            }
        }
    }

    # Prepare menu based on files
    $MenuBuilder = [ordered] @{}
    # lets build top level based on folders to keep the order of menus
    foreach ($Folder in $Folders.Keys) {
        if (-not $MenuBuilder[$Folder]) {
            $MenuBuilder[$Folder] = [ordered] @{}
        }
    }
    # We now build menu from files
    foreach ($Entry in $Files) {
        if (-not $MenuBuilder[$Entry.Menu][$Entry.Name]) {
            $MenuBuilder[$Entry.Menu][$Entry.Name] = @{
                Current = $Entry
                All     = [System.Collections.Generic.List[Object]]::new()
            }
        } else {
            if ($MenuBuilder[$Entry.Menu][$Entry.Name]['Current'].Date -lt $Entry.Date) {
                $MenuBuilder[$Entry.Menu][$Entry.Name]['Current'] = $Entry

            }
        }
        $MenuBuilder[$Entry.Menu][$Entry.Name]['All'].Add($Entry)
    }

    New-HTMLReport -OutputElements $OutputElements -Logo $Logo -MenuBuilder $MenuBuilder -Configuration $Configuration -TopStats $TopStats -Files $Files -ShowHTML:$ShowHTML.IsPresent -HTMLPath $HTMLPath -Online:$Online.IsPresent -Force:$Force.IsPresent

    # Export statistics to file to create charts later on
    if ($StatisticsPath) {
        $TopStats | Export-Clixml -Depth 3 -LiteralPath $StatisticsPath
    }
}