function Set-Statistics {
    [cmdletBinding()]
    param(
        [System.Collections.IDictionary] $Statistics,
        [alias('Computer', 'User')][Object] $ADObject
    )
    $Statistics['Accounts total']++

    if ($ADObject.PSObject.Properties.Name -contains 'Enabled') {
        if ($ADObject.Enabled -eq $false) {
            $Statistics['Accounts disabled']++
        } else {
            $Statistics['Accounts enabled']++
        }
    }
    if ($ADObject.PSObject.Properties.Name -contains 'ManagerStatus') {
        if ($ADObject.ManagerStatus -eq 'Missing') {
            $Statistics['Manager missing']++
        } elseif ($ADObject.ManagerStatus -eq 'Disabled') {
            $Statistics['Manager disabled']++
        } else {
            $Statistics['Manager enabled']++
        }
    }

    if ($ADObject.PSObject.Properties.Name -contains 'ManagerLastLogonDays') {
        if ($ADObject.ManagerLastLogonDays -ge 0) {
            if ($ADObject.ManagerLastLogonDays -gt 180) {
                $Statistics['Manager account logged in over 180 days ago']++
            } elseif ($ADObject.ManagerLastLogonDays -gt 90) {
                $Statistics['Manager account logged in over 90 days ago']++
            }
        } elseif ($null -eq $ADObject.ManagerLastLogonDays -and $ADObject.Manager) {
            # Manager is set, but never logged in
            $Statistics['Manager never logged in']++
        }
    }
    if ($ADObject.PSObject.Properties.Name -contains 'PasswordLastDays') {
        if ($ADObject.PasswordLastDays -ge 0) {
            if ($ADObject.PasswordLastDays -gt 360) {
                $Statistics['Accounts password over 360 Days']++
            }
        } elseif ($null -eq $ADObject.PasswordLastDays) {
            $Statistics['Accounts password never set']++
        }
    }
    if ($ADObject.PSObject.Properties.Name -contains 'LastLogonDays') {
        if ($ADObject.LastLogonDays -ge 0) {
            if ($ADObject.LastLogonDays -gt 180) {
                $Statistics['Accounts logged in over 180 days ago']++
            } elseif ($ADObject.LastLogonDays -gt 90) {
                $Statistics['Accounts logged in over 90 days ago']++
            }
        } elseif ($null -eq $ADObject.LastLogonDays) {
            $Statistics['Accounts never logged in']++
        }
    }
    if ($ADObject.PSObject.Properties.Name -contains 'PasswordNotRequired') {
        if ($ADObject.PasswordNotRequired -eq $true) {
            $Statistics['Accounts password not required']++
        }
    }
    if ($ADObject.PSObject.Properties.Name -contains 'PasswordExpired') {
        if ($ADObject.PasswordExpired -eq $true) {
            $Statistics['Accounts password expired']++
        }
    }
    if ($ADObject.PSObject.Properties.Name -contains 'PasswordNeverExpires') {
        if ($ADObject.PasswordNeverExpires -eq $true) {
            $Statistics['Accounts password never expires']++
        }
    }

    if ($ADObject.PSObject.Properties.Name -contains 'IsServiceAccount') {
        if ($ADObject.IsServiceAccount) {
            $Statistics['Accounts being service account']++
        } else {
            $Statistics['Accounts not service account']++
        }
    }
}