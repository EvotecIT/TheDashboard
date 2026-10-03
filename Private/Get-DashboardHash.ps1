function Get-DashboardHash {
    [CmdletBinding()]
    param([string] $Text)
    $Hasher = [Security.Cryptography.SHA256]::Create()
    try { ([BitConverter]::ToString($Hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text)))).Replace('-', '').ToLowerInvariant() }
    finally { $Hasher.Dispose() }
}
