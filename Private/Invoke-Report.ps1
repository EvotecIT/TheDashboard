function Invoke-Report {
    [cmdletBinding()]
    param(
        [string] $FilePath,
        [string] $Title,
        [System.Collections.IDictionary] $Statistics,
        [System.Collections.IDictionary] $Summary,
        [Array] $Users
    )
    New-HTMLTabOption -RemoveShadow -BorderRadius 0px -BackgroundColor DimGray -TextColor White -BackgroundColorActive DeepSkyBlue
    New-HTMLTableOption -DataStore JavaScript -BoolAsString -ArrayJoin
    New-HTMLSectionOption -BorderRadius 0px -RemoveShadow

    New-HTMLHeader {
        New-HTMLSection -Invisible {
            New-HTMLSection {
                New-HTMLText -Text "Report generated on $(Get-Date)" -Color Blue
            } -JustifyContent flex-start -Invisible
            New-HTMLSection {
                New-HTMLText -Text "$Title" -Color Blue
            } -JustifyContent flex-end -Invisible
        }
    }
    New-HTMLTab -Name 'Summary' {
        New-HTMLSection -Invisible {
            New-HTMLSection -HeaderText 'All' {
                New-HTMLContainer {
                    New-HTMLChart -Height 450 {
                        New-ChartPie -Name 'Accounts enabled' -Value $Statistics['Summary']['Accounts enabled'] -Color PastelGreen
                        New-ChartPie -Name 'Accounts disabled' -Value $Statistics['Summary']['Accounts disabled'] -Color Salmon
                    }
                }
                New-HTMLContainer {
                    New-HTMLChart -Height 450 {
                        New-ChartPie -Name 'Manager enabled' -Value $Statistics['Summary']['Manager enabled'] -Color PastelGreen
                        New-ChartPie -Name 'Manager disabled' -Value $Statistics['Summary']['Manager disabled'] -Color Salmon
                        New-ChartPie -Name 'Manager missing' -Value $Statistics['Summary']['Manager missing'] -Color Amaranth
                    }
                }
                New-HTMLContainer {
                    New-HTMLChart -Height 450 {
                        New-ChartBarOptions -Distributed
                        New-ChartAxisY -LabelMaxWidth 300 -LabelAlign left -Show
                        New-ChartLegend -LegendPosition bottom -Color TurquoiseBlue, MediumSlateBlue, BlueMarguerite, FreeSpeechRed, VenetianRed, Malachite, Razzmatazz, Mahogany, Crimson, Cerise, Valencia, DarkPink, Amaranth, Flamingo, Sorbus, CoralRed, Scarlet, MediumSeaGreen, SunsetOrange
                        foreach ($Bar in $Statistics['Summary'].Keys) {
                            New-ChartBar -Name $Bar -Value $Statistics['Summary'][$Bar]
                        }
                    }
                }
            }
        }
        New-HTMLSection -Invisible {
            New-HTMLSection -HeaderText 'Summary' -HeaderBackGroundColor DeepSkyBlue {
                New-HTMLList {
                    foreach ($Region in $Statistics['All'].Keys | Sort-Object) {
                        New-HTMLListItem -Text $Region -FontWeight bold {
                            New-HTMLList {
                                foreach ($Type in $Statistics['All'][$Region].Keys | Sort-Object) {
                                    New-HTMLListItem -Text "$Type", " - ", $Statistics['All'][$Region][$Type] -FontWeight normal, normal, bold
                                }
                            }
                        }
                    }
                }
            }
            New-HTMLSection -HeaderText 'Enabled Only' -HeaderBackGroundColor Salmon {
                New-HTMLList {
                    foreach ($Region in $Statistics['Enabled'].Keys | Sort-Object) {
                        New-HTMLListItem -Text $Region -FontWeight bold {
                            New-HTMLList {
                                foreach ($Type in $Statistics['Enabled'][$Region].Keys | Sort-Object) {
                                    New-HTMLListItem -Text "$Type", " - ", $Statistics['Enabled'][$Region][$Type] -FontWeight normal, normal, bold
                                }
                            }
                        }
                    }
                }
            }
            New-HTMLSection -HeaderText 'Disabled Only' -HeaderBackGroundColor Grey {
                New-HTMLList {
                    foreach ($Region in $Statistics['Disabled'].Keys | Sort-Object) {
                        New-HTMLListItem -Text $Region -FontWeight bold {
                            New-HTMLList {
                                foreach ($Type in $Statistics['Disabled'][$Region].Keys | Sort-Object) {
                                    New-HTMLListItem -Text "$Type", " - ", $Statistics['Disabled'][$Region][$Type] -FontWeight normal, normal, bold
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    New-HTMLTab -Name 'All Accounts' {
        New-HTMLSection -Invisible {
            New-HTMLSection -HeaderText 'Enabled Only' -HeaderBackGroundColor Salmon {
                New-HTMLList {
                    New-HTMLList {
                        foreach ($Type in $Statistics['SummaryEnabled'].Keys | Sort-Object) {
                            New-HTMLListItem -Text "$Type", " - ", $Statistics['SummaryEnabled'][$Type] -FontWeight normal, normal, bold
                        }
                    }
                }
            }
            New-HTMLSection -HeaderText 'Disabled Only' -HeaderBackGroundColor Grey {
                New-HTMLList {
                    New-HTMLList {
                        foreach ($Type in $Statistics['SummaryDisabled'].Keys | Sort-Object) {
                            New-HTMLListItem -Text "$Type", " - ", $Statistics['SummaryDisabled'][$Type] -FontWeight normal, normal, bold
                        }
                    }
                }
            }
        }
        New-HTMLTable -DataTable $Users -Filtering -SearchBuilder {
            New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $true -BackgroundColor LimeGreen -FailBackgroundColor BlizzardBlue

            New-HTMLTableCondition -Name 'IsServiceAccount' -ComparisonType string -Operator eq -Value $true -BackgroundColor LimeGreen -FailBackgroundColor Alizarin
            New-HTMLTableCondition -Name 'IsMissing' -ComparisonType string -Operator eq -Value $false -BackgroundColor LimeGreen -FailBackgroundColor Alizarin

            New-HTMLTableCondition -Name 'ManagerLastLogonDays' -ComparisonType number -Operator ge -Value 0 -BackgroundColor LimeGreen
            New-HTMLTableCondition -Name 'ManagerLastLogonDays' -ComparisonType number -Operator gt -Value 30 -BackgroundColor Orange
            New-HTMLTableCondition -Name 'ManagerLastLogonDays' -ComparisonType number -Operator gt -Value 90 -BackgroundColor Alizarin
            New-HTMLTableCondition -Name 'ManagerStatus' -ComparisonType string -Operator eq -Value 'Missing' -BackgroundColor Alizarin
            New-HTMLTableCondition -Name 'ManagerStatus' -ComparisonType string -Operator eq -Value 'Disabled' -BackgroundColor Alizarin
            New-HTMLTableCondition -Name 'ManagerStatus' -ComparisonType string -Operator eq -Value 'Enabled' -BackgroundColor LimeGreen

            New-HTMLTableCondition -Name 'LastLogonDays' -ComparisonType number -Operator gt -Value 60 -BackgroundColor Alizarin
            New-HTMLTableCondition -Name 'PasswordLastDays' -ComparisonType number -Operator ge -Value 0 -BackgroundColor LimeGreen
            New-HTMLTableCondition -Name 'PasswordLastDays' -ComparisonType number -Operator gt -Value 300 -BackgroundColor Orange
            New-HTMLTableCondition -Name 'PasswordLastDays' -ComparisonType number -Operator gt -Value 360 -BackgroundColor Alizarin

            New-HTMLTableCondition -Name 'PasswordNotRequired' -ComparisonType string -Operator eq -Value $false -BackgroundColor LimeGreen -FailBackgroundColor Alizarin
            New-HTMLTableCondition -Name 'PasswordExpired' -ComparisonType string -Operator eq -Value $false -BackgroundColor LimeGreen -FailBackgroundColor Alizarin
        }
    }
    foreach ($Region in $Summary['All'].Keys | Sort-Object) {
        New-HTMLTab -Name $Region {
            New-HTMLSection -Invisible {
                New-HTMLSection -HeaderText 'Enabled Only' -HeaderBackGroundColor Salmon {
                    New-HTMLList {
                        foreach ($Type in $Statistics['Enabled'][$Region].Keys | Sort-Object) {
                            New-HTMLListItem -Text "$Type", " - ", $Statistics['Enabled'][$Region][$Type] -FontWeight normal, normal, bold
                        }
                    }
                }
                New-HTMLSection -HeaderText 'Disabled Only' -HeaderBackGroundColor Grey {
                    New-HTMLList {
                        foreach ($Type in $Statistics['Disabled'][$Region].Keys | Sort-Object) {
                            New-HTMLListItem -Text "$Type", " - ", $Statistics['Disabled'][$Region][$Type] -FontWeight normal, normal, bold
                        }
                    }
                }
            }
            New-HTMLTable -DataTable $Summary['All'][$Region] -Filtering -SearchBuilder {
                New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $true -BackgroundColor LimeGreen -FailBackgroundColor BlizzardBlue

                New-HTMLTableCondition -Name 'LastLogonDays' -ComparisonType number -Operator gt -Value 60 -BackgroundColor Alizarin
                New-HTMLTableCondition -Name 'PasswordLastDays' -ComparisonType number -Operator ge -Value 0 -BackgroundColor LimeGreen
                New-HTMLTableCondition -Name 'PasswordLastDays' -ComparisonType number -Operator gt -Value 300 -BackgroundColor Orange
                New-HTMLTableCondition -Name 'PasswordLastDays' -ComparisonType number -Operator gt -Value 360 -BackgroundColor Alizarin
                New-HTMLTableCondition -Name 'PasswordLastDays' -ComparisonType string -Operator eq -Value '' -BackgroundColor Alizarin

                New-HTMLTableCondition -Name 'PasswordNotRequired' -ComparisonType string -Operator eq -Value $false -BackgroundColor LimeGreen -FailBackgroundColor Alizarin
                New-HTMLTableCondition -Name 'PasswordExpired' -ComparisonType string -Operator eq -Value $false -BackgroundColor LimeGreen -FailBackgroundColor Alizarin

                if ($Region -ne 'Managed Service Accounts') {
                    New-HTMLTableCondition -Name 'IsServiceAccount' -ComparisonType string -Operator eq -Value $true -BackgroundColor LimeGreen -FailBackgroundColor Alizarin
                    New-HTMLTableCondition -Name 'IsMissing' -ComparisonType string -Operator eq -Value $false -BackgroundColor LimeGreen -FailBackgroundColor Alizarin

                    New-HTMLTableCondition -Name 'ManagerLastLogonDays' -ComparisonType number -Operator ge -Value 0 -BackgroundColor LimeGreen
                    New-HTMLTableCondition -Name 'ManagerLastLogonDays' -ComparisonType number -Operator gt -Value 30 -BackgroundColor Orange
                    New-HTMLTableCondition -Name 'ManagerLastLogonDays' -ComparisonType number -Operator gt -Value 90 -BackgroundColor Alizarin
                    New-HTMLTableCondition -Name 'ManagerLastLogonDays' -ComparisonType string -Operator eq -Value '' -BackgroundColor Alizarin
                    New-HTMLTableCondition -Name 'ManagerStatus' -ComparisonType string -Operator eq -Value 'Missing' -BackgroundColor Alizarin
                    New-HTMLTableCondition -Name 'ManagerStatus' -ComparisonType string -Operator eq -Value 'Disabled' -BackgroundColor Alizarin
                    New-HTMLTableCondition -Name 'ManagerStatus' -ComparisonType string -Operator eq -Value 'Enabled' -BackgroundColor LimeGreen
                } else {
                    New-HTMLTableCondition -Name 'IsMissing' -ComparisonType string -Operator eq -Value $false -BackgroundColor DeepSkyBlue -FailBackgroundColor DeepSkyBlue
                    New-HTMLTableCondition -Name 'ManagerStatus' -ComparisonType string -Operator eq -Value 'Not available' -BackgroundColor DeepSkyBlue
                }

            }
        }
    }
}