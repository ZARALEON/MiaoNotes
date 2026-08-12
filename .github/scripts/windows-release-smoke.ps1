param(
  [Parameter(Mandatory = $true)]
  [string]$ReleaseDirectory
)

$ErrorActionPreference = 'Stop'

$resolvedReleaseDirectory = (Resolve-Path -LiteralPath $ReleaseDirectory).Path
$executable = Join-Path $resolvedReleaseDirectory 'miaonotes.exe'
if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) {
  throw "Windows release smoke test cannot find $executable."
}

$temporaryRoot = if ([string]::IsNullOrWhiteSpace($env:RUNNER_TEMP)) {
  [IO.Path]::GetTempPath()
} else {
  $env:RUNNER_TEMP
}
$smokeRoot = Join-Path `
  $temporaryRoot `
  "miaonotes-release-smoke-$([Guid]::NewGuid().ToString('N'))"
$dataDirectory = Join-Path $smokeRoot 'data'
New-Item -ItemType Directory -Path $dataDirectory -Force | Out-Null

$previousDataDirectory = $env:MIAONOTES_DATA_DIRECTORY
$process = $null
try {
  $env:MIAONOTES_DATA_DIRECTORY = $dataDirectory
  $process = Start-Process `
    -FilePath $executable `
    -WorkingDirectory $resolvedReleaseDirectory `
    -PassThru

  $database = Join-Path $dataDirectory 'miaonotes.db'
  $deadline = [DateTime]::UtcNow.AddSeconds(30)
  $windowReady = $false
  do {
    Start-Sleep -Milliseconds 250
    $process.Refresh()
    if ($process.HasExited) {
      throw "MiaoNotes exited before startup completed (exit code $($process.ExitCode))."
    }
    $windowReady = $process.MainWindowHandle -ne 0
  } until (
    ($windowReady -and (Test-Path -LiteralPath $database -PathType Leaf)) -or
    [DateTime]::UtcNow -ge $deadline
  )

  if (-not $windowReady) {
    throw 'MiaoNotes did not create its main window within 30 seconds.'
  }
  if (-not (Test-Path -LiteralPath $database -PathType Leaf)) {
    throw 'MiaoNotes did not create its isolated SQLite database.'
  }

  Write-Host "Windows release smoke test passed for process $($process.Id)."
} finally {
  if ($null -ne $process) {
    $process.Refresh()
    if (-not $process.HasExited) {
      $null = $process.CloseMainWindow()
      if (-not $process.WaitForExit(5000)) {
        Stop-Process -Id $process.Id -Force
        $process.WaitForExit()
      }
    }
  }

  if ($null -eq $previousDataDirectory) {
    Remove-Item Env:MIAONOTES_DATA_DIRECTORY -ErrorAction SilentlyContinue
  } else {
    $env:MIAONOTES_DATA_DIRECTORY = $previousDataDirectory
  }
}
