function Get-DashboardReplacementKeys {
    <#
    .SYNOPSIS
    Returns replacement keys in a deterministic application order.

    .PARAMETER Dictionary
    Replacement map. Ordered maps retain their declared order; other maps apply
    longer text keys first and sort equal-length keys by text.

    .OUTPUTS
    Dictionary keys in replacement order, or no output for a null map.
    #>
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $Dictionary
    )
    if ($null -eq $Dictionary) {
        return
    }
    if ($Dictionary -is [System.Collections.Specialized.OrderedDictionary]) {
        $Dictionary.Keys
    } else {
        # Hashtable enumeration is process-dependent. Longer literal replacements run first.
        $Dictionary.Keys | Sort-Object @{
            Expression = { ([string] $_).Length }
            Descending = $true
        }, @{
            Expression = { [string] $_ }
        }
    }
}
