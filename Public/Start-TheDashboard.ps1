function Start-TheDashboard {
    [cmdletBinding()]
    param(
        [ScriptBlock] $Elements,
        [string] $HTMLPath,
        [string] $ExcelPath,
        [string] $StatisticsPath,
        #[parameter(Mandatory)][ValidateSet('ServiceAccounts', 'UsersPasswordNeverExpire', 'ComputersLimitedINS')][string[]] $Type,
        [string] $Logo,
        [System.Collections.IDictionary] $Limits,
        [System.Collections.IDictionary] $Folders,
        [System.Collections.IDictionary] $Replacements,
        [switch] $ShowHTML
    )
    $TopStats = [ordered] @{}
    $Cache = @{}

    <#
    $Properties = 'DistinguishedName', 'mail', 'LastLogonDate', 'PasswordLastSet', 'DisplayName', 'Manager', 'Description', 'PasswordNeverExpires', 'PasswordNotRequired', 'PasswordExpired', 'UserPrincipalName', 'SamAccountName', 'CannotChangePassword', 'TrustedForDelegation', 'TrustedToAuthForDelegation'
    $AllUsers = Get-ADUser -Filter * -Properties $Properties
    $PropertiesComputer = 'DistinguishedName', 'LastLogonDate', 'PasswordLastSet', 'Enabled', 'DnsHostName', 'PasswordNeverExpires', 'PasswordNotRequired', 'PasswordExpired', 'Manager', 'OperatingSystemVersion', 'OperatingSystem' , 'TrustedForDelegation'
    $AllComputers = Get-ADComputer -Filter * -Properties $PropertiesComputer
    $AllGroups = Get-ADGroup -Filter *
    $AllGroupPolicies = Get-GPO -All
    #>

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
        $TopStats = Import-Clixml -LiteralPath $StatisticsPath
    }
    $TodayString = Get-Date
    $TopStats[$TodayString] = [ordered] @{}
    $TopStats[$TodayString]['Date'] = Get-Date
    $TopStats[$TodayString]['Computers'] = $AllComputers.Count
    $TopStats[$TodayString]['Users'] = $AllUsers.Count
    $TopStats[$TodayString]['Groups'] = $AllGroups.Count
    $TopStats[$TodayString]['Group Policies'] = $AllGroupPolicies.Count


    # create menu information based on files
    $Files = foreach ($FolderName in $Folders.Keys) {

        $Folder = $Folders[$FolderName]
        $FilesInFolder = Get-ChildItem -LiteralPath $Folders[$FolderName].Path -ErrorAction SilentlyContinue -Filter *.html
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
    $Files = $Files | Sort-Object -Property Name

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

    New-HTMLReport -Elements $Elements -Logo $Logo -MenuBuilder $MenuBuilder -Configuration $Configuration -Limits $Limits -TopStats $TopStats -Files $Files -ShowHTML:$ShowHTML.IsPresent -HTMLPath $HTMLPath

    # Export statistics to file to create charts later on
    if ($StatisticsPath) {
        $TopStats | Export-Clixml -Depth 3 -LiteralPath $StatisticsPath
    }
}