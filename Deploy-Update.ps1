﻿Import-Module Admin

function Deploy-Update {
  param (
    [switch] $Parallel,
    [string] $Target
  )

  AssertRunningAsAdmin

  $time = [Diagnostics.Stopwatch]::StartNew()

  foreach ($app in $(Get-ChildItem -Path $(Join-Path $(if ($Target) { $Target } else { "D:" }) "Apps") -Directory -Name)) {
    Deploy-App -App $app -Update -Parallel: $Parallel -Target: $Target
  }

  $time.Stop()
  Write-Host "All done in $($time.Elapsed.ToString("mm\:ss\.fff"))" -ForegroundColor DarkGray
}

Set-Alias update Deploy-Update

