function Export-ADReportToExcel {
    [cmdletBinding()]
    param(
        [string] $ReportPathExcel,
        [Array] $Objects,
        [System.Collections.IDictionary] $Summary,
        [string] $SummaryTitle,
        [switch] $ExportSummary
    )

    if ($ExportSummary) {
        $Objects | ConvertTo-Excel -FilePath $ReportPathExcel -ExcelWorkSheetName $SummaryTitle -AutoFilter -AutoFit
    }
    foreach ($Region in $Summary.Keys | Sort-Object) {
        $Summary[$Region] | ConvertTo-Excel -FilePath $ReportPathExcel -ExcelWorkSheetName $Region -AutoFilter -AutoFit
    }
}