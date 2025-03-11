function Copy-HTMLFiles {
    [cmdletbinding()]
    param(
        [System.Collections.IDictionary] $Folders,
        [string] $Extension
    )

    Write-Color -Text '[i]', "[TheDashboard] ", 'Copying or HTML files', ' [Informative] ' -Color Yellow, DarkGray, Yellow, DarkGray, Magenta
    foreach ($FolderName in $Folders.Keys) {
        if ($Folders[$FolderName].CopyFrom) {
            foreach ($Path in $Folders[$FolderName].CopyFrom) {
                foreach ($File in Get-ChildItem -LiteralPath $Path -Filter "*$Extension" -Recurse) {
                    $Destination = $File.FullName.Replace($Path, $Folders[$FolderName].Path)
                    $DIrectoryName = [io.path]::GetDirectoryName($Destination)
                    $null = New-Item -Path $DIrectoryName -ItemType Directory -Force
                    Copy-Item -LiteralPath $File.FullName -Destination $Destination -Force -ErrorAction Stop
                }
                foreach ($Ext in $Folders[$FolderName].Extension) {
                    foreach ($File in Get-ChildItem -LiteralPath $Path -Filter "*$Ext" -Recurse) {
                        $Destination = $File.FullName.Replace($Path, $Folders[$FolderName].Path)
                        $DIrectoryName = [io.path]::GetDirectoryName($Destination)
                        $null = New-Item -Path $DIrectoryName -ItemType Directory -Force
                        Copy-Item -LiteralPath $File.FullName -Destination $Destination -Force -ErrorAction Stop
                    }
                }
            }
        }
        if ($Folders[$FolderName].MoveFrom) {
            foreach ($Path in $Folders[$FolderName].MoveFrom) {
                foreach ($File in Get-ChildItem -LiteralPath $Path -Filter "*$Extension" -Recurse) {
                    $Destination = $File.FullName.Replace($Path, $Folders[$FolderName].Path)
                    $DIrectoryName = [io.path]::GetDirectoryName($Destination)
                    $null = New-Item -Path $DIrectoryName -ItemType Directory -Force
                    Move-Item -LiteralPath $File.FullName -Destination $Destination -Force -ErrorAction Stop
                }
                foreach ($Ext in $Folders[$FolderName].Extension) {
                    foreach ($File in Get-ChildItem -LiteralPath $Path -Filter "*$Ext" -Recurse) {
                        $Destination = $File.FullName.Replace($Path, $Folders[$FolderName].Path)
                        $DIrectoryName = [io.path]::GetDirectoryName($Destination)
                        $null = New-Item -Path $DIrectoryName -ItemType Directory -Force
                        Move-Item -LiteralPath $File.FullName -Destination $Destination -Force -ErrorAction Stop
                    }
                }
            }
        }
    }
}