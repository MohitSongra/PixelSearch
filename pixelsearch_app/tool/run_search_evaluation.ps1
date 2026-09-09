#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Device,
    [string]$Flutter = 'C:\src\flutter\bin\flutter.bat',
    [string]$Adb = "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe",
    [switch]$BackupOnly
)

$ErrorActionPreference = 'Stop'
$app = 'com.pixelsearch.pixelsearch'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$output = Join-Path $root 'local_evaluation'
New-Item -ItemType Directory -Path $output -Force | Out-Null

function Invoke-AdbChecked([string[]]$Arguments) {
    $result = & $Adb -s $Device @Arguments
    if ($LASTEXITCODE -ne 0) { throw "ADB failed: $Arguments" }
    return $result
}

function Export-AdbBytes([string[]]$Arguments, [string]$Destination) {
    $start = [Diagnostics.ProcessStartInfo]::new($Adb)
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    foreach ($argument in (@('-s', $Device) + $Arguments)) {
        $start.ArgumentList.Add($argument)
    }
    $process = [Diagnostics.Process]::Start($start)
    $errors = $process.StandardError.ReadToEndAsync()
    $file = [IO.File]::Open($Destination, [IO.FileMode]::CreateNew)
    try { $process.StandardOutput.BaseStream.CopyTo($file) }
    finally { $file.Dispose() }
    $process.WaitForExit()
    $errorText = $errors.GetAwaiter().GetResult()
    $code = $process.ExitCode
    $process.Dispose()
    if ($code -ne 0) { throw "ADB export failed ($code): $errorText" }
}

Push-Location $root
try {
    $running = & $Adb -s $Device shell pidof $app
    if ($running) {
        throw 'Finish/cancel indexing, then close PixelSearch with Android Settings > Force stop before this offline snapshot. No process is stopped automatically.'
    }
    Invoke-AdbChecked @('shell', 'run-as', $app, 'test', '-f', 'app_flutter/pixelsearch.sqlite') | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
    $backup = Join-Path $output "app-data-$stamp.tar"
    Export-AdbBytes @('exec-out', 'run-as', $app, 'tar', '-cf', '-', '.') $backup
    $contents = & tar.exe -tf $backup
    if ($LASTEXITCODE -ne 0 -or './app_flutter/pixelsearch.sqlite' -notin $contents) {
        throw 'Backup archive failed validation. No test will be run.'
    }
    $hash = (Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash
    Write-Host "Private app backup: $backup"
    Write-Host "SHA256: $hash"
    if ($BackupOnly) { return }

    # Flutter currently defaults to uninstalling the application after a test.
    # Never omit this flag when evaluating a user's existing private library.
    $testCode = 1
    try {
        & $Flutter test --no-pub --no-uninstall integration_test/search_diagnostics_test.dart -d $Device
        $testCode = $LASTEXITCODE
        if ($testCode -eq 0) {
            $report = Join-Path $output "device-ranking-$stamp.json"
            Export-AdbBytes @('exec-out', 'run-as', $app, 'cat', 'files/search_evaluation/latest_report.json') $report
            Get-Content -LiteralPath $report -Raw | ConvertFrom-Json | Out-Null
            Write-Host "Private measured report: $report"
        }
    }
    finally {
        & $Flutter build apk --debug --no-pub
        if ($LASTEXITCODE -ne 0) { throw 'Normal app rebuild failed. Backup retained; no uninstall or data clear attempted.' }
        Invoke-AdbChecked @('install', '-r', 'build/app/outputs/flutter-apk/app-debug.apk') | Out-Null
    }
    if ($testCode -ne 0) { throw 'Evaluation failed. Normal app restored and the pre-run backup retained.' }
}
finally { Pop-Location }
