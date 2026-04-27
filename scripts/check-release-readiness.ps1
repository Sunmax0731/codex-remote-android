param(
  [string]$Tag = "",
  [switch]$RequireReleaseNotes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$PubspecPath = Join-Path $RepoRoot "app\pubspec.yaml"
$ReleaseRunbookPath = Join-Path $RepoRoot "docs\release-runbook.md"

$pubspec = Get-Content -LiteralPath $PubspecPath -Raw
if ($pubspec -notmatch "(?m)^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$") {
  throw "app/pubspec.yaml must contain version: <versionName>+<versionCode>"
}

$versionName = $Matches[1]
$versionCode = [int]$Matches[2]
if ($versionCode -lt 1) {
  throw "versionCode must be greater than zero."
}

if (-not (Test-Path -LiteralPath $ReleaseRunbookPath)) {
  throw "Release runbook was not found: docs/release-runbook.md"
}

if ($Tag) {
  $expectedTag = "v$versionName"
  if ($Tag -ne $expectedTag) {
    throw "Release tag $Tag does not match app/pubspec.yaml versionName. Expected $expectedTag."
  }
  $RequireReleaseNotes = $true
}

if ($RequireReleaseNotes) {
  $releaseDocPath = Join-Path $RepoRoot "docs\releases\$versionName.md"
  if (-not (Test-Path -LiteralPath $releaseDocPath)) {
    throw "Release evidence document was not found: docs/releases/$versionName.md"
  }

  $releaseDoc = Get-Content -LiteralPath $releaseDocPath -Raw
  if ($releaseDoc -notmatch [regex]::Escape($versionName)) {
    throw "Release evidence document does not mention versionName $versionName."
  }
  if ($releaseDoc -notmatch "(?m)(versionCode|build number).*$versionCode") {
    throw "Release evidence document does not mention versionCode $versionCode."
  }
}

$summary = [ordered]@{
  versionName = $versionName
  versionCode = $versionCode
  expectedTag = "v$versionName"
  releaseNotesRequired = [bool]$RequireReleaseNotes
}

$summary | ConvertTo-Json -Depth 3
