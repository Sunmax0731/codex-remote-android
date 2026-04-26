Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$bridgeRoot = Resolve-Path (Join-Path $scriptRoot '..')
$repoRoot = Resolve-Path (Join-Path $bridgeRoot '..')
$stagingRoot = Join-Path $bridgeRoot '.local\distribution'
$packageRoot = Join-Path $stagingRoot 'codex-remote-pc-bridge'
$zipPath = Join-Path $stagingRoot 'codex-remote-pc-bridge.zip'

Push-Location $bridgeRoot
try {
  & npm.cmd run build
} finally {
  Pop-Location
}

if (Test-Path $packageRoot) {
  Remove-Item -LiteralPath $packageRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $packageRoot | Out-Null

$items = @(
  'README.md',
  'config.example.json',
  'package.json',
  'package-lock.json',
  'tsconfig.json',
  'src',
  'scripts',
  'setup-web',
  'dist'
)

foreach ($item in $items) {
  $source = Join-Path $bridgeRoot $item
  $destination = Join-Path $packageRoot $item
  Copy-Item -LiteralPath $source -Destination $destination -Recurse -Force
}

$docsRoot = Join-Path $packageRoot 'docs'
New-Item -ItemType Directory -Force -Path $docsRoot | Out-Null
Copy-Item -LiteralPath (Join-Path $repoRoot 'docs\pc-bridge-distribution.md') -Destination $docsRoot -Force
Copy-Item -LiteralPath (Join-Path $repoRoot 'docs\distribution-prep.md') -Destination $docsRoot -Force

Remove-Item -LiteralPath (Join-Path $packageRoot 'config.local.json') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $packageRoot 'node_modules') -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $packageRoot 'logs') -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $packageRoot '.local') -Recurse -Force -ErrorAction SilentlyContinue

if (Test-Path $zipPath) {
  Remove-Item -LiteralPath $zipPath -Force
}
Compress-Archive -Path $packageRoot -DestinationPath $zipPath -Force

Write-Output "PC bridge distribution package written:"
Write-Output $zipPath
