$ErrorActionPreference = "Stop"

$repoFirebaseDir = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$rulesPath = Join-Path $repoFirebaseDir "firestore.rules"
$configPath = Join-Path $repoFirebaseDir "firebase.test.json"
$testCommand = 'node --test --test-force-exit lib/tests/rules/**/*.test.js'
$exitCode = 0
$previousDebug = $env:DEBUG

try {
  $env:DEBUG = ""
  firebase emulators:exec --config $configPath --only firestore --project codex-remote-rules-test $testCommand
  $exitCode = $LASTEXITCODE
} finally {
  $env:DEBUG = $previousDebug
  Get-CimInstance Win32_Process |
    Where-Object {
      $_.CommandLine -like '*cloud-firestore-emulator*' -and
      $_.CommandLine -like '*--port 18080*' -and
      $_.CommandLine -like "*$rulesPath*"
    } |
    ForEach-Object {
      Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    }
}

exit $exitCode
