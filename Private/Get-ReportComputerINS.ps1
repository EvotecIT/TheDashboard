function Get-ReportComputerINS {
    [cmdletBinding()]
    param(
        [Array] $AllComputers,
        [System.Collections.IDictionary]$Cache
    )

    $Today = Get-Date
    $Statistics = [ordered] @{
        Summary         = [ordered] @{
            <#
            'Accounts total'                              = 0
            'Accounts disabled'                           = 0
            'Accounts enabled'                            = 0
            'Manager missing'                             = 0
            'Manager disabled'                            = 0
            'Manager enabled'                             = 0
            'Manager account logged in over 180 days ago' = 0
            'Manager account logged in over 90 days ago'  = 0
            'Manager never logged in'                     = 0
            'Accounts password over 360 Days'             = 0
            'Accounts password never set'                 = 0
            'Accounts logged in over 180 days ago'        = 0
            'Accounts logged in over 90 days ago'         = 0
            'Accounts never logged in'                    = 0
            'Accounts password not required'              = 0
            'Accounts password expired'                   = 0
            'Accounts password never expires'             = 0
            'Accounts being service account'              = 0
            'Accounts not service account'                = 0
            #>
        }
        SummaryEnabled  = [ordered] @{}
        SummaryDisabled = [ordered] @{}
        All             = [ordered] @{}
        Enabled         = [ordered] @{}
        Disabled        = [ordered] @{}
    }
    $Summary = [ordered] @{
        Summary  = [ordered]@{}
        All      = [ordered]@{}
        Enabled  = [ordered] @{}
        Disabled = [ordered] @{}
    }

    $ComputerList = foreach ($Computer in $AllComputers) {
        if ($Computer.DistinguishedName -like "*,OU=INS,*") {
            Get-PreparedComputerInformation -Computer $Computer
        }
    }

    foreach ($Computer in $ComputerList) {
        <#
        if (-not $Summary[$Computer.Region]) {
            $Summary[$Computer.Region] = [System.Collections.Generic.List[PSCustomObject]]::new()
            $Statistics[$Computer.Region] = [ordered] @{}
        }
        $Summary[$Computer.Region].add($Computer)
        $Statistics[$Computer.Region]['Computer without LAPS']++

        if ($Computer.Enabled -eq $false) {
            $Statistics[$Computer.Region]['Computer disabled']++
        }

        if ($Computer.PasswordLastDays -ge 0) {
            if ($Computer.PasswordLastDays -gt 360) {
                $Statistics[$Computer.Region]['Computer password over 360 Days']++
            }
        } elseif ($null -eq $Computer.PasswordLastDays) {
            $Statistics[$Computer.Region]['Computer password never set']++
        }
        if ($Computer.LastLogonDays -ge 0) {
            if ($Computer.LastLogonDays -gt 180) {
                $Statistics[$Computer.Region]['Computer logged in over 180 days ago']++
            } elseif ($Computer.LastLogonDays -gt 90) {
                $Statistics[$Computer.Region]['Computer logged in over 90 days ago']++
            } elseif ($Computer.LastLogonDays -gt 30) {
                #$Statistics[$Computer.Region]['Computer LoggedIn Over 30 days ago']++
            }
        } elseif ($null -eq $Computer.LastLogonDays) {
            $Statistics[$Computer.Region]['Computer never logged in']++
        }

        if ($Computer.PasswordNotRequired -eq $true) {
            $Statistics[$Computer.Region]['Computer password not required']++
        }
        if ($Computer.PasswordExpired -eq $true) {
            $Statistics[$Computer.Region]['Computer password expired']++
        }
        #>


        if (-not $Summary['All'][$Computer.Level0]) {
            $Summary['All'][$Computer.Level0] = [System.Collections.Generic.List[PSCustomObject]]::new()
            $Statistics['All'][$Computer.Level0] = [ordered] @{}
        }
        if (-not $Summary['Disabled'][$Computer.Level0]) {
            $Summary['Disabled'][$Computer.Level0] = [System.Collections.Generic.List[PSCustomObject]]::new()
            $Statistics['Disabled'][$Computer.Level0] = [ordered] @{}
        }
        if (-not $Summary['Enabled'][$Computer.Level0]) {
            $Summary['Enabled'][$Computer.Level0] = [System.Collections.Generic.List[PSCustomObject]]::new()
            $Statistics['Enabled'][$Computer.Level0] = [ordered] @{}
        }
        $Summary['All'][$Computer.Level0].add($Computer)

        if ($Computer.Enabled -eq $false) {
            $Summary['Disabled'][$Computer.Level0].add($Computer)
            # $Statistics['All'][$Computer.Region]['Account disabled']++
        } else {
            $Summary['Enabled'][$Computer.Level0].add($Computer)
        }

        Set-Statistics -Statistics $Statistics['All'][$Computer.Level0] -User $Computer

        # Summary
        Set-Statistics -Statistics $Statistics['Summary'] -User $Computer
        # Enabled / Disabled
        if ($Computer.Enabled -eq $false) {
            Set-Statistics -Statistics $Statistics['SummaryDisabled'] -User $Computer
            Set-Statistics -Statistics $Statistics['Disabled'][$Computer.Level0] -User $Computer
        } else {
            Set-Statistics -Statistics $Statistics['SummaryEnabled'] -User $Computer
            Set-Statistics -Statistics $Statistics['Enabled'][$Computer.Level0] -User $Computer
        }
    }
    @{
        Summary    = $Summary
        Statistics = $Statistics
        Objects    = $ComputerList
    }
}