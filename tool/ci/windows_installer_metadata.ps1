# Check the actual MSI SummaryInformation template, independently of its name.
# https://learn.microsoft.com/windows/win32/msi/template-summary
param([Parameter(Mandatory = $true)][string]$Path)
$ErrorActionPreference = 'Stop'
$installer = New-Object -ComObject WindowsInstaller.Installer
$database = $installer.OpenDatabase((Resolve-Path $Path).Path, 0)
$summary = $database.SummaryInformation(0)
$template = $summary.Property(7)
if (($template -split ';')[0] -cne 'x64') {
    throw "Expected x64 MSI metadata; found $template"
}
Write-Output "MSI target verified: $template"
