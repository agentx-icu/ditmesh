# Dot-source from the existing hosted-only installer smoke. This file performs
# no registry, dump, environment, user-data or target-process changes.
function Get-ExactProcessCrashContext {
  param(
    [Parameter(Mandatory=$true)][Diagnostics.Process]$Process,
    [Parameter(Mandatory=$true)][string]$ExpectedExecutablePath
  )
  if (-not $IsWindows -or $env:GITHUB_ACTIONS -ne 'true' -or $env:RUNNER_ENVIRONMENT -ne 'github-hosted') {
    throw 'Crash diagnostics are restricted to a disposable GitHub-hosted Windows runner'
  }
  $Process.Refresh()
  if ($Process.HasExited) { throw 'Cannot snapshot an exited installer-smoke process' }
  $expected = [IO.Path]::GetFullPath($ExpectedExecutablePath)
  if (-not [string]::Equals([IO.Path]::GetFullPath($Process.MainModule.FileName), $expected, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Crash diagnostics refused a process outside the exact installed executable'
  }
  $modules = @($Process.Modules | ForEach-Object {
    [pscustomobject]@{
      name = $_.ModuleName
      path = [IO.Path]::GetFullPath($_.FileName)
      base_address = ('0x{0:x16}' -f $_.BaseAddress.ToInt64())
      size = $_.ModuleMemorySize
    }
  })
  return [pscustomobject]@{
    process_id = $Process.Id
    executable = $expected
    started_at_utc = $Process.StartTime.ToUniversalTime()
    modules = $modules
  }
}

function Write-ExactProcessCrashEvents {
  param(
    [Parameter(Mandatory=$true)]$Context,
    [Parameter(Mandatory=$true)][string]$OutputPath,
    [ValidateRange(0,10)][int]$WaitSeconds = 5
  )
  # Diagnostics must not replace the primary smoke failure. Only numeric error
  # identity is recorded if event access/parsing itself fails; never raw XML or
  # localized Message (which can contain unrelated process/user information).
  $report = [ordered]@{
    process_id = $Context.process_id
    executable = $Context.executable
    started_at_utc = $Context.started_at_utc.ToString('o')
    collection = 'not_found'
    modules_before_close = @($Context.modules)
    application_errors = @()
  }
  try {
    if (-not $IsWindows -or $env:GITHUB_ACTIONS -ne 'true' -or $env:RUNNER_ENVIRONMENT -ne 'github-hosted') {
      throw 'Crash diagnostics are restricted to a disposable GitHub-hosted Windows runner'
    }
    $deadline = [DateTime]::UtcNow.AddSeconds($WaitSeconds)
    do {
      # Event.System.Execution.ProcessID is the reporting process. Match the
      # EventData ProcessId of the crashed application instead.
      $queryErrors = @()
      $events = @(Get-WinEvent -FilterHashtable @{
        LogName = 'Application'
        ProviderName = 'Application Error'
        Id = 1000
        StartTime = $Context.started_at_utc.AddSeconds(-1)
      } -MaxEvents 64 -ErrorAction SilentlyContinue -ErrorVariable queryErrors)
      $errors = @()
      foreach ($event in $events) {
        $document = [xml]$event.ToXml()
        $fields = @{}
        # Providers can emit empty/unnamed event data. XML's PowerShell dot
        # adapter throws under StrictMode for absent nodes, so select real
        # named elements without exposing unrelated event contents.
        foreach ($data in $document.SelectNodes("/*[local-name()='Event']/*[local-name()='EventData']/*[local-name()='Data'][@Name]")) {
          $name = $data.GetAttribute('Name')
          if ($name) { $fields[$name] = [string]$data.InnerText }
        }
        if (-not $fields.ContainsKey('ProcessId') -or -not $fields.ContainsKey('AppPath')) { continue }
        $rawId = $fields['ProcessId']
        $eventProcessId = if ($rawId -match '^0x[0-9a-f]+$') {
          [Convert]::ToInt64($rawId.Substring(2), 16)
        } elseif ($rawId -match '^\d+$') {
          [long]$rawId
        } else { -1 }
        if ($eventProcessId -ne $Context.process_id) { continue }
        if (-not [string]::Equals([IO.Path]::GetFullPath($fields['AppPath']), $Context.executable, [StringComparison]::OrdinalIgnoreCase)) { continue }
        # PID + exact executable + short start-time window identify this fresh
        # test launch. Also check process creation time whenever Windows emits it.
        if ($fields.ContainsKey('ProcessCreationTime') -and $fields['ProcessCreationTime'] -match '^0x[0-9a-f]+$') {
          $created = [DateTime]::FromFileTimeUtc([Convert]::ToInt64($fields['ProcessCreationTime'].Substring(2), 16))
          if ([Math]::Abs(($created - $Context.started_at_utc).TotalSeconds) -gt 1) { continue }
        }
        $entry = [ordered]@{ event_id = $event.Id; recorded_at_utc = $event.TimeCreated.ToUniversalTime().ToString('o') }
        foreach ($key in @('AppName', 'AppVersion', 'ModuleName', 'ModuleVersion', 'ExceptionCode', 'FaultingOffset', 'ModulePath')) {
          if ($fields.ContainsKey($key)) { $entry[$key] = $fields[$key] }
        }
        # A module-relative fault offset plus this same process's pre-close
        # module base can reconstruct the address without reading process memory.
        if ($fields.ContainsKey('ModulePath') -and $fields.ContainsKey('FaultingOffset') -and $fields['FaultingOffset'] -match '^(0x)?[0-9a-f]+$') {
          $module = @($Context.modules | Where-Object { [string]::Equals($_.path, $fields['ModulePath'], [StringComparison]::OrdinalIgnoreCase) })
          if ($module.Count -eq 1) {
            $offset = [Convert]::ToInt64(($fields['FaultingOffset'] -replace '^0x', ''), 16)
            if ($offset -ge 0 -and $offset -lt $module[0].size) {
              $base = [Convert]::ToInt64($module[0].base_address.Substring(2), 16)
              $entry['exception_address_from_preclose_module'] = ('0x{0:x16}' -f ($base + $offset))
            }
          }
        }
        $errors += [pscustomobject]$entry
      }
      if ($errors.Count) {
        $report.collection = 'matched'
        $report.application_errors = $errors
        break
      }
      if ($queryErrors.Count -and $queryErrors[0].FullyQualifiedErrorId -notlike 'NoMatchingEventsFound*') {
        $report.collection = 'event_query_failed'
        $report['diagnostic_error_id'] = [string]$queryErrors[0].FullyQualifiedErrorId
        break
      }
      if ([DateTime]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 500 }
    } while ([DateTime]::UtcNow -lt $deadline)
  } catch {
    $report.collection = 'diagnostic_failed'
    $report['diagnostic_error_type'] = $_.Exception.GetType().FullName
    $report['diagnostic_hresult'] = $_.Exception.HResult
    $report['diagnostic_script_line'] = $_.InvocationInfo.ScriptLineNumber
  }
  try {
    $report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath -Encoding utf8
  } catch {
    Write-Warning 'Failed to write the scoped crash-event diagnostic; the original smoke outcome remains authoritative'
  }
}
