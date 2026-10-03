function Get-DashboardReplacementKeys {
    [CmdletBinding()]
    param([System.Collections.IDictionary] $Dictionary)
    if ($null -eq $Dictionary) { return }
    if ($Dictionary -is [System.Collections.Specialized.OrderedDictionary]) {
        $Dictionary.Keys
    } else {
        # Hashtable enumeration is process-dependent. Longer literal replacements run first.
        $Dictionary.Keys | Sort-Object @{ Expression = { ([string] $_).Length }; Descending = $true }, @{ Expression = { [string] $_ } }
    }
}
