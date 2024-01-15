$ExtensionFrom = '.html'
$ExtensionTo = '.aspx'

#$ExtensionFrom = '.aspx'
#$ExtensionTo = '.html'

$Files = Get-ChildItem -Path $PSScriptRoot\Reports -File -Recurse -Include "*$ExtensionFrom"
foreach ($File in $Files) {
    if ($File.Extension -eq $ExtensionFrom) {
        # Rename extension to .aspx
        $NewName = $File.FullName -replace "$($ExtensionFrom)$", $ExtensionTo
        Rename-Item -Path $File.FullName -NewName $NewName -Force
    }
}