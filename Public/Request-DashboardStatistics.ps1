function Request-DashboardStatistics {
    [cmdletbinding()]
    param(
        [string] $StatisticsPath
    )
    $TopStats = [ordered] @{}
    $Cache = @{}

    $Forest = Get-ADForest
    $AllUsers = $Forest.Domains | ForEach-Object { Get-ADUser -Filter * -Properties 'DistinguishedName' -Server $_ }
    $AllComputers = $Forest.Domains | ForEach-Object { Get-ADComputer -Filter * -Properties 'DistinguishedName' -Server $_ }
    $AllGroups = $Forest.Domains | ForEach-Object { Get-ADGroup -Filter * -Server $_ }
    $AllGroupPolicies = $Forest.Domains | ForEach-Object { Get-GPO -All -Domain $_ }


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

    # foreach ($U in $AllUsers) {
    #     $Cache[$U.DistinguishedName] = $U
    # }
    # foreach ($C in $AllComputers) {
    #     $Cache[$C.DistinguishedName] = $C
    # }

    if ($StatisticsPath -and (Test-Path -LiteralPath $StatisticsPath)) {
        $TopStats = Import-Clixml -LiteralPath $StatisticsPath
    }
    $TodayString = Get-Date
    $TopStats[$TodayString] = [ordered] @{}
    $TopStats[$TodayString]['Date'] = Get-Date
    $TopStats[$TodayString]['Computers'] = $AllComputers.Count
    $TopStats[$TodayString]['ComputersEnabled'] = $ComputerEnabled
    $TopStats[$TodayString]['ComputersDisabled'] = $ComputerDisabled
    $TopStats[$TodayString]['Users'] = $AllUsers.Count
    $TopStats[$TodayString]['UsersEnabled'] = $UserEnabled
    $TopStats[$TodayString]['UsersDisabled'] = $UserDisabled
    $TopStats[$TodayString]['Groups'] = $AllGroups.Count
    $TopStats[$TodayString]['Group Policies'] = $AllGroupPolicies.Count
    if ($StatisticsPath) {
        $TopStats | Export-Clixml -LiteralPath $StatisticsPath
    }
    $TopStats
}

# $Stats = Request-DashboardStatistics -StatisticsPath 'C:\Temp\DashboardStatistics.xml'
# $Stats