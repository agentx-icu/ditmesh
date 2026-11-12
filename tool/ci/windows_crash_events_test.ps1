$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'windows_crash_events.ps1')

# Schema/selection tests run in a child PowerShell process. Only the platform
# gate and Get-WinEvent are mocked; no Windows APIs, registry or target mutation.
Set-Variable -Name IsWindows -Value $true -Force -Scope Script
$env:GITHUB_ACTIONS = 'true'
$env:RUNNER_ENVIRONMENT = 'github-hosted'
$script:inputEvents = @()
function Get-WinEvent {
  [CmdletBinding()]
  param([hashtable]$FilterHashtable, [int]$MaxEvents)
  if ($FilterHashtable.LogName -ne 'Application' -or $FilterHashtable.ProviderName -ne 'Application Error' -or $FilterHashtable.Id -ne 1000 -or $MaxEvents -ne 64) {
    throw 'Incorrect diagnostic query scope'
  }
  return $script:inputEvents
}
function New-FixtureEvent {
  param([long]$TargetId = 7356, [string]$Executable = $script:context.executable, [int]$StartedOffsetSeconds = 0, [string]$Offset = '0000000000000010')
  $created = '0x{0:x}' -f $script:context.started_at_utc.AddSeconds($StartedOffsetSeconds).ToFileTimeUtc()
  $escapedExecutable = [Security.SecurityElement]::Escape($Executable)
  $escapedModule = [Security.SecurityElement]::Escape($script:context.modules[0].path)
  $body = @"
<Event xmlns="http://schemas.microsoft.com/win/2004/08/events/event"><System><Execution ProcessID="99999" /></System><EventData>
<Data Name="AppName">ditmesh.exe</Data><Data Name="ProcessId">0x$('{0:x}' -f $TargetId)</Data><Data Name="AppPath">$escapedExecutable</Data><Data Name="ProcessCreationTime">$created</Data>
<Data Name="ModuleName">flutter_windows.dll</Data><Data Name="ModulePath">$escapedModule</Data><Data Name="ExceptionCode">c000041d</Data><Data Name="FaultingOffset">$Offset</Data>
<Data Name="SecretField">SHOULD_NEVER_BE_PUBLISHED</Data></EventData></Event>
"@
  $event = [pscustomobject]@{ Id = 1000; TimeCreated = $script:context.started_at_utc.AddSeconds(10); fixture = $body }
  return ($event | Add-Member -MemberType ScriptMethod -Name ToXml -Value { return $this.fixture } -PassThru)
}
function Assert([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw $Message }
}
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('ditmesh-crash-schema-' + [guid]::NewGuid().ToString('N'))
[void](New-Item -ItemType Directory -Path $fixtureRoot)
$script:context = [pscustomobject]@{
  process_id = 7356
  executable = [IO.Path]::GetFullPath((Join-Path $fixtureRoot 'ditmesh & fixture.exe'))
  started_at_utc = [DateTime]::SpecifyKind([DateTime]'2026-10-23T04:31:40', [DateTimeKind]::Utc)
  modules = @([pscustomobject]@{ name = 'flutter_windows.dll'; path = [IO.Path]::GetFullPath((Join-Path $fixtureRoot 'flutter_windows.dll')); base_address = '0x0000000000001000'; size = 4096 })
}
$output = Join-Path $fixtureRoot 'synthetic-crash-evidence.json'
try {
  $script:inputEvents = @(New-FixtureEvent)
  Write-ExactProcessCrashEvents -Context $context -OutputPath $output -WaitSeconds 0
  $text = Get-Content -LiteralPath $output -Raw
  $result = $text | ConvertFrom-Json
  Assert ($result.collection -eq 'matched') 'The exact EventData PID/executable/creation time must match despite a different reporting PID'
  Assert ($result.application_errors[0].ExceptionCode -eq 'c000041d') 'Exception code must remain unchanged'
  Assert ($result.application_errors[0].exception_address_from_preclose_module -eq '0x0000000000001010') 'Address must use the same-process pre-close module base plus checked offset'
  Assert (-not $text.Contains('SHOULD_NEVER_BE_PUBLISHED')) 'Raw XML/unrecognized event fields must never escape'
  Write-Host 'PASS exact identity, exception address and field whitelist'

  foreach ($event in @((New-FixtureEvent -TargetId 999), (New-FixtureEvent -Executable (Join-Path $fixtureRoot 'other.exe')), (New-FixtureEvent -StartedOffsetSeconds -10))) {
    $script:inputEvents = @($event)
    Write-ExactProcessCrashEvents -Context $context -OutputPath $output -WaitSeconds 0
    $result = Get-Content -LiteralPath $output -Raw | ConvertFrom-Json
    Assert ($result.collection -eq 'not_found') 'A foreign PID, executable or reused PID from a different start must be rejected'
  }
  Write-Host 'PASS foreign PID, foreign executable and reused PID rejection'

  $script:inputEvents = @(New-FixtureEvent -Offset '0000000000002000')
  Write-ExactProcessCrashEvents -Context $context -OutputPath $output -WaitSeconds 0
  $result = Get-Content -LiteralPath $output -Raw | ConvertFrom-Json
  Assert ($result.collection -eq 'matched') 'An out-of-image fault must still preserve the event'
  Assert (-not ($result.application_errors[0].PSObject.Properties.Name -contains 'exception_address_from_preclose_module')) 'An out-of-image offset must not fabricate an exception address'
  Write-Host 'PASS out-of-image address is not inferred'

  $script:inputEvents = @()
  Write-ExactProcessCrashEvents -Context $context -OutputPath $output -WaitSeconds 0
  $result = Get-Content -LiteralPath $output -Raw | ConvertFrom-Json
  Assert ($result.collection -eq 'not_found') 'No event must remain explicitly inconclusive'
  Write-Host 'PASS no-event outcome remains inconclusive'

  foreach ($xml in @('<Event />', '<Event><EventData /></Event>',
                     '<Event><EventData><Data>unnamed</Data></EventData></Event>',
                     '<Event><EventData><Data Name="" /></EventData></Event>')) {
    $event = [pscustomobject]@{ fixture = $xml }
    $event | Add-Member -MemberType ScriptMethod -Name ToXml -Value { return $this.fixture }
    $script:inputEvents = @($event)
    Write-ExactProcessCrashEvents -Context $context -OutputPath $output -WaitSeconds 0
    $result = Get-Content -LiteralPath $output -Raw | ConvertFrom-Json
    Assert ($result.collection -eq 'not_found') 'Missing or unnamed EventData must be ignored under StrictMode'
  }
  Write-Host 'PASS empty or unnamed event schema is ignored safely'
} finally {
  if (Test-Path -LiteralPath $output) { Remove-Item -LiteralPath $output }
  Remove-Item -LiteralPath $fixtureRoot
}
