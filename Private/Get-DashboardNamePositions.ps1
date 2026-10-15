function Get-DashboardNamePositions {
    <#
    .SYNOPSIS
    Selects the filename parts used for a report's display name.

    .DESCRIPTION
    Ordered rules use their declared precedence. Unordered rules prefer the most
    specific matching pattern and reject equally specific conflicting rules.
    The '*' rule is always a fallback.

    .PARAMETER Name
    Report name after the BeforeSplit replacements have been applied.

    .PARAMETER Rules
    A position, a list of positions, or a dictionary mapping patterns to positions.

    .OUTPUTS
    The selected positions. Returns position zero when no rule applies.
    #>
    [CmdletBinding()]
    param(
        [string] $Name,
        [object] $Rules
    )
    if ($null -eq $Rules) {
        return 0
    }
    if ($Rules -isnot [System.Collections.IDictionary]) {
        return $Rules
    }
    $MatchesFound = @($Rules.Keys | Where-Object { $_ -ne '*' -and $Name -like $_ })
    if ($Rules -isnot [System.Collections.Specialized.OrderedDictionary]) {
        $SortProperties = @(
            @{
                Expression = { ($_ -replace '[*?\[\]]', '').Length }
                Descending = $true
            }
            # Dictionary keys can have other types; compare ties as text.
            @{
                Expression = { [string] $_ }
            }
        )
        $MatchesFound = @($MatchesFound | Sort-Object -Property $SortProperties)
        if ($MatchesFound.Count -gt 1) {
            $FirstSpecificity = ($MatchesFound[0] -replace '[*?\[\]]', '').Length
            $SecondSpecificity = ($MatchesFound[1] -replace '[*?\[\]]', '').Length
            $FirstPositions = $Rules[$MatchesFound[0]] -join ','
            $SecondPositions = $Rules[$MatchesFound[1]] -join ','
            if ($FirstSpecificity -eq $SecondSpecificity -and $FirstPositions -ne $SecondPositions) {
                throw "Equally specific naming rules match '$Name'. Use an [ordered] dictionary to specify their precedence."
            }
        }
    }
    if ($MatchesFound.Count) {
        return $Rules[$MatchesFound[0]]
    }
    if ($Rules.Contains('*')) {
        return $Rules['*']
    }
    0
}
