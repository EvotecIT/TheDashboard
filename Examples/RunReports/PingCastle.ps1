$PingCastleFolder = "C:\Support\Tools\PingCastle"
$SourcePath = "C:\Support\GitHub\TheDashboard\Examples\Reports\Temp"
$DestinationPath = "C:\Support\GitHub\TheDashboard\Examples\Reports\Security"

if ((Test-Path -LiteralPath $PingCastleFolder) -and (Test-Path -LiteralPath $SourcePath) -and (Test-Path -LiteralPath $DestinationPath)) {
    Set-Location -LiteralPath $SourcePath
    & "$PingCastleFolder\PingCastle.exe" --healthcheck --server * --reachable

    $AllFiles = Get-ChildItem -LiteralPath $SourcePath
    foreach ($File in $AllFiles) {
        $DomainName = $File.BaseName.Replace("ad_hc_", '')
        $Name = "PingCastle-Domain-$($DomainName)_$(Get-Date -f yyyy-MM-dd_HHmmss -Date $File.CreationTime)$($File.Extension)"

        Move-Item -LiteralPath $File.FullName -Destination ([io.path]::Combine($DestinationPath, $Name))
    }
} else {
    Write-Warning -Message "PingCastleFolder [$PingCastleFolder] or SourcePath [$SourcePath] or DestinationPath [$DestinationPath] doesn't exist"
}