# Check the actual MSI SummaryInformation template, independently of its name.
# https://learn.microsoft.com/windows/win32/msi/template-summary
param([Parameter(Mandatory = $true)][string]$Path)
$ErrorActionPreference = 'Stop'
$installer = New-Object -ComObject WindowsInstaller.Installer
$summary = $null
try {
    # SummaryInformation and Property are indexed COM properties, not methods.
    $summary = $installer.GetType().InvokeMember('SummaryInformation', 'GetProperty', $null, $installer, @((Resolve-Path $Path).Path, 0))
    $template = $summary.GetType().InvokeMember('Property', 'GetProperty', $null, $summary, @(7))
    if (($template -split ';')[0] -cne 'x64') {
        throw "Expected x64 MSI metadata; found $template"
    }
    Write-Output "MSI target verified: $template"
} finally {
    if ($summary) { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($summary) }
    [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($installer)
}
