function Repair-DashboardEncoding {
    <#
    .SYNOPSIS
    Repairs encoding issues in dashboard HTML/ASPX files to ensure proper display of emojis and special characters.

    .DESCRIPTION
    This function detects and fixes encoding issues in dashboard report files, particularly focusing on:
    - Converting UTF-8 with BOM to UTF-8 without BOM (recommended for web content)
    - Ensuring consistent encoding across all report files
    - Fixing emoji display issues caused by encoding mismatches

    The function uses the encoding detection and conversion capabilities from PSSharedGoods module.

    .PARAMETER Path
    The path to the dashboard reports directory or a specific file to repair.

    .PARAMETER Extensions
    File extensions to process. Defaults to @('.html', '.aspx', '.htm')

    .PARAMETER TargetEncoding
    The target encoding for all files. Defaults to 'UTF8' (without BOM) which is recommended for web content.

    .PARAMETER SourceEncoding
    The expected source encoding. If not specified, the function will auto-detect the encoding of each file.

    .PARAMETER Recurse
    Process files in subdirectories recursively. Default is $true.

    .PARAMETER CreateBackups
    Create backup files before conversion. Backups are created with .bak extension.

    .PARAMETER Force
    Convert files even when their detected encoding doesn't match the expected source encoding.

    .PARAMETER AddOneMinute
    Adds one minute to the file's LastWriteTime after conversion. This is useful when you want to trigger
    file change detection in systems that monitor file timestamps.

    .PARAMETER WhatIf
    Shows what would happen if the cmdlet runs without actually making changes.

    .PARAMETER PassThru
    Return detailed results of the encoding repair process.

    .EXAMPLE
    Repair-DashboardEncoding -Path "C:\Reports" -WhatIf

    Preview what encoding changes would be made to all HTML/ASPX files in the Reports directory.

    .EXAMPLE
    Repair-DashboardEncoding -Path "C:\Reports" -CreateBackups

    Repair encoding issues in all dashboard files, creating backups before making changes.

    .EXAMPLE
    Repair-DashboardEncoding -Path "C:\Reports\Dashboard.aspx" -TargetEncoding UTF8

    Convert a specific file to UTF-8 without BOM.

    .EXAMPLE
    Repair-DashboardEncoding -Path "C:\Reports" -Extensions @('.html', '.aspx', '.htm') -PassThru

    Repair encoding for all HTML-type files and return detailed results.

    .NOTES
    This function requires the PSSharedGoods module for encoding detection and conversion.
    UTF-8 without BOM is recommended for web content to avoid display issues with emojis and special characters.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [string[]] $Extensions = @('.html', '.aspx', '.htm'),

        [ValidateSet('ASCII', 'BigEndianUnicode', 'Unicode', 'UTF7', 'UTF8', 'UTF8BOM', 'UTF32')]
        [string] $TargetEncoding = 'UTF8',

        [ValidateSet('ASCII', 'BigEndianUnicode', 'Unicode', 'UTF7', 'UTF8', 'UTF8BOM', 'UTF32', 'Auto')]
        [string] $SourceEncoding = 'Auto',

        [switch] $Recurse = $true,

        [switch] $CreateBackups,

        [switch] $Force,

        [switch] $AddOneMinute,

        [switch] $PassThru
    )

    begin {
        # Check if PSSharedGoods module is available
        if (-not (Get-Command -Name Get-FileEncoding -ErrorAction SilentlyContinue)) {
            throw "This function requires the PSSharedGoods module. Please install it using: Install-Module PSSharedGoods"
        }

        Write-Color -Text '[i]', '[Encoding] ', 'Starting encoding repair process' -Color Yellow, DarkGray, Yellow

        $summary = @{
            TotalFiles = 0
            ProcessedFiles = 0
            ConvertedFiles = 0
            SkippedFiles = 0
            ErrorFiles = 0
            FilesWithBOM = 0
            FilesWithEmojis = 0
            StartTime = Get-Date
        }

        $results = @()
    }

    process {
        # Determine if path is file or directory
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            $files = @(Get-Item -LiteralPath $Path)
            Write-Verbose "Processing single file: $Path"
        } elseif (Test-Path -LiteralPath $Path -PathType Container) {
            Write-Verbose "Processing directory: $Path"
            $gciParams = @{
                Path = $Path
                File = $true
                Recurse = $Recurse
            }

            $files = @()
            foreach ($ext in $Extensions) {
                $files += Get-ChildItem @gciParams -Filter "*$ext"
            }
        } else {
            throw "Path not found: $Path"
        }

        $summary.TotalFiles = $files.Count
        Write-Color -Text '[i]', '[Encoding] ', "Found $($files.Count) files to process" -Color Yellow, DarkGray, Yellow

        foreach ($file in $files) {
            try {
                # Detect current encoding
                $currentEncoding = Get-FileEncoding -Path $file.FullName
                Write-Verbose "File: $($file.Name) - Current encoding: $currentEncoding"

                # Check if file contains emojis or special Unicode characters
                $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
                # PowerShell 5.1 compatible regex - using surrogate pairs for emoji detection
                # Emojis: 1F300-1F9FF, 2600-26FF, 2700-27BF
                # Also check for common emoji presentation sequences
                $hasEmojis = $content -match '[\uD83C-\uD83E][\uDC00-\uDFFF]|[\u2600-\u27BF]|[\u2300-\u23FF]|[\u2B00-\u2BFF]'
                if ($hasEmojis) {
                    $summary.FilesWithEmojis++
                    Write-Verbose "File contains emoji characters"
                }

                # Track files with BOM
                if ($currentEncoding -eq 'UTF8BOM') {
                    $summary.FilesWithBOM++
                }

                # Determine if conversion is needed
                $needsConversion = $false
                $conversionReason = ""

                if ($SourceEncoding -eq 'Auto') {
                    # Auto mode: Convert if not matching target encoding
                    if ($currentEncoding -ne $TargetEncoding) {
                        $needsConversion = $true
                        $conversionReason = "Current encoding ($currentEncoding) differs from target ($TargetEncoding)"
                    }
                } else {
                    # Specific source mode: Convert only if matching source and different from target
                    if ($currentEncoding -eq $SourceEncoding -and $currentEncoding -ne $TargetEncoding) {
                        $needsConversion = $true
                        $conversionReason = "Matches source encoding ($SourceEncoding) and needs conversion to $TargetEncoding"
                    } elseif ($Force -and $currentEncoding -ne $TargetEncoding) {
                        $needsConversion = $true
                        $conversionReason = "Force flag set, converting from $currentEncoding to $TargetEncoding"
                    }
                }

                if ($needsConversion) {
                    if ($PSCmdlet.ShouldProcess($file.FullName, "Convert encoding from $currentEncoding to $TargetEncoding")) {
                        Write-Color -Text '[i]', '[Encoding] ', "Converting: ", $file.Name, " ($currentEncoding -> $TargetEncoding)" -Color Yellow, DarkGray, Yellow, White, Green

                        # Store original timestamps
                        $originalCreationTime = $file.CreationTime
                        $originalLastWriteTime = $file.LastWriteTime

                        # Create backup if requested
                        if ($CreateBackups) {
                            $backupPath = "$($file.FullName).bak"
                            Copy-Item -LiteralPath $file.FullName -Destination $backupPath -Force
                            Write-Verbose "Created backup: $backupPath"
                        }

                        # Use Convert-FileEncoding from PSSharedGoods
                        $convertParams = @{
                            Path = $file.FullName
                            SourceEncoding = if ($SourceEncoding -eq 'Auto') { $currentEncoding } else { $SourceEncoding }
                            TargetEncoding = $TargetEncoding
                            Force = $Force
                        }

                        Convert-FileEncoding @convertParams

                        # Restore original timestamps
                        $item = Get-Item -LiteralPath $file.FullName
                        $item.CreationTime = $originalCreationTime
                        if ($AddOneMinute) {
                            $item.LastWriteTime = $originalLastWriteTime.AddMinutes(1)
                            Write-Verbose "Added one minute to LastWriteTime"
                        } else {
                            $item.LastWriteTime = $originalLastWriteTime
                        }

                        $summary.ConvertedFiles++
                        $summary.ProcessedFiles++

                        if ($PassThru) {
                            $results += [PSCustomObject]@{
                                FilePath = $file.FullName
                                OriginalEncoding = $currentEncoding
                                NewEncoding = $TargetEncoding
                                Status = 'Converted'
                                HasEmojis = $hasEmojis
                                Reason = $conversionReason
                                BackupCreated = $CreateBackups
                            }
                        }
                    }
                } else {
                    $summary.SkippedFiles++
                    $skipReason = if ($currentEncoding -eq $TargetEncoding) {
                        "Already in target encoding ($TargetEncoding)"
                    } else {
                        "Does not match source encoding criteria"
                    }

                    Write-Verbose "Skipping $($file.Name): $skipReason"

                    if ($PassThru) {
                        $results += [PSCustomObject]@{
                            FilePath = $file.FullName
                            OriginalEncoding = $currentEncoding
                            NewEncoding = $currentEncoding
                            Status = 'Skipped'
                            HasEmojis = $hasEmojis
                            Reason = $skipReason
                            BackupCreated = $false
                        }
                    }
                }

            } catch {
                $summary.ErrorFiles++
                Write-Color -Text '[e]', '[Encoding] ', "Error processing ", $file.Name, ": ", $_.Exception.Message -Color Red, DarkGray, Red, White, Red, Yellow

                if ($PassThru) {
                    $results += [PSCustomObject]@{
                        FilePath = $file.FullName
                        OriginalEncoding = 'Unknown'
                        NewEncoding = 'Unknown'
                        Status = 'Error'
                        HasEmojis = $false
                        Reason = $_.Exception.Message
                        BackupCreated = $false
                    }
                }
            }
        }
    }

    end {
        $summary.EndTime = Get-Date
        $summary.Duration = $summary.EndTime - $summary.StartTime

        # Display summary
        Write-Color -Text "`n[i]", "[Encoding] ", "Repair Summary:" -Color Yellow, DarkGray, Cyan
        Write-Color -Text "  Total files found: ", $summary.TotalFiles -Color Gray, White
        Write-Color -Text "  Files processed: ", $summary.ProcessedFiles -Color Gray, White
        Write-Color -Text "  Files converted: ", $summary.ConvertedFiles -Color Gray, Green
        Write-Color -Text "  Files skipped: ", $summary.SkippedFiles -Color Gray, Yellow
        Write-Color -Text "  Files with errors: ", $summary.ErrorFiles -Color Gray, Red
        Write-Color -Text "  Files with BOM: ", $summary.FilesWithBOM -Color Gray, Cyan
        Write-Color -Text "  Files with emojis: ", $summary.FilesWithEmojis -Color Gray, Magenta
        Write-Color -Text "  Duration: ", "$($summary.Duration.TotalSeconds.ToString('F2')) seconds" -Color Gray, White

        if ($summary.ConvertedFiles -gt 0 -and $TargetEncoding -eq 'UTF8') {
            Write-Color -Text "`n[i]", "[Encoding] ", "Files converted to UTF-8 without BOM for better web compatibility" -Color Yellow, DarkGray, Green
        }

        if ($CreateBackups -and $summary.ConvertedFiles -gt 0) {
            Write-Color -Text "[i]", "[Encoding] ", "Backup files created with .bak extension" -Color Yellow, DarkGray, Cyan
        }

        if ($PassThru) {
            return $results
        }
    }
}