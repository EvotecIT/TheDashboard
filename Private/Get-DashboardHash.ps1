function Get-DashboardHash {
    <#
    .SYNOPSIS
    Computes a stable SHA256 hash of UTF-8 text.

    .PARAMETER Text
    Text used for a generated filename suffix or a generation fingerprint.

    .OUTPUTS
    A lowercase hexadecimal hash string.
    #>
    [CmdletBinding()]
    param(
        [string] $Text
    )
    $Hasher = [Security.Cryptography.SHA256]::Create()
    try {
        ([BitConverter]::ToString($Hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text)))).Replace('-', '').ToLowerInvariant()
    } finally {
        $Hasher.Dispose()
    }
}
