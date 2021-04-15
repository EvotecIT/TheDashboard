function Set-Statistics {
    [cmdletBinding()]
    param(
        [System.Collections.IDictionary] $Statistics,
        $User
    )
    $Statistics['Accounts total']++

    if ($User.Enabled -eq $false) {
        $Statistics['Accounts disabled']++
    } else {
        $Statistics['Accounts enabled']++
    }

    if ($User.ManagerStatus -eq 'Missing') {
        $Statistics['Manager missing']++
    } elseif ($User.ManagerStatus -eq 'Disabled') {
        $Statistics['Manager disabled']++
    } else {
        $Statistics['Manager enabled']++
    }

    if ($User.ManagerLastLogonDays -ge 0) {
        if ($User.ManagerLastLogonDays -gt 180) {
            $Statistics['Manager account logged in over 180 days ago']++
        } elseif ($User.ManagerLastLogonDays -gt 90) {
            $Statistics['Manager account logged in over 90 days ago']++
        }
    } elseif ($null -eq $User.ManagerLastLogonDays -and $User.Manager) {
        # Manager is set, but never logged in
        $Statistics['Manager never logged in']++
    }

    if ($User.PasswordLastDays -ge 0) {
        if ($User.PasswordLastDays -gt 360) {
            $Statistics['Accounts password over 360 Days']++
        }
    } elseif ($null -eq $User.PasswordLastDays) {
        $Statistics['Accounts password never set']++
    }
    if ($User.LastLogonDays -ge 0) {
        if ($User.LastLogonDays -gt 180) {
            $Statistics['Accounts logged in over 180 days ago']++
        } elseif ($User.LastLogonDays -gt 90) {
            $Statistics['Accounts logged in over 90 days ago']++
        }
    } elseif ($null -eq $User.LastLogonDays) {
        $Statistics['Accounts never logged in']++
    }

    if ($User.PasswordNotRequired -eq $true) {
        $Statistics['Accounts password not required']++
    }
    if ($User.PasswordExpired -eq $true) {
        $Statistics['Accounts password expired']++
    }
    if ($User.PasswordNeverExpires -eq $true) {
        $Statistics['Accounts password never expires']++
    }

    if ($User.IsServiceAccount) {
        $Statistics['Accounts being service account']++
    } else {
        $Statistics['Accounts not service account']++
    }

}