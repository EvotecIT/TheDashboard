function Get-DashboardNamePositions {
    [CmdletBinding()]
    param([string] $Name, [object] $Rules)
    if ($null -eq $Rules) { return 0 }
    if ($Rules -isnot [System.Collections.IDictionary]) { return $Rules }
    $MatchesFound = @($Rules.Keys | Where-Object { $_ -ne '*' -and $Name -like $_ })
    if ($Rules -isnot [System.Collections.Specialized.OrderedDictionary]) {
        $MatchesFound = @($MatchesFound | Sort-Object @{ Expression = { ([string] $_ -replace '[*?\[\]]', '').Length }; Descending = $true }, @{ Expression = { [string] $_ } })
        if ($MatchesFound.Count -gt 1) {
            $First = ([string] $MatchesFound[0] -replace '[*?\[\]]', '').Length
            $Second = ([string] $MatchesFound[1] -replace '[*?\[\]]', '').Length
            if ($First -eq $Second -and ($Rules[$MatchesFound[0]] -join ',') -ne ($Rules[$MatchesFound[1]] -join ',')) {
                throw "Equally specific naming rules match '$Name'. Use an [ordered] dictionary to specify their precedence."
            }
        }
    }
    if ($MatchesFound.Count) { return $Rules[$MatchesFound[0]] }
    if ($Rules.Contains('*')) { return $Rules['*'] }
    0
}
