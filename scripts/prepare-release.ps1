param(
  [string]$Version = "",
  [string]$PreviousVersionCode = "",
  [switch]$SkipApkBuild,
  [switch]$SkipPcBridgePackage,
  [switch]$NoClean
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem

$RepoRoot = Split-Path -Parent $PSScriptRoot
$AppDir = Join-Path $RepoRoot "app"
$BridgeDir = Join-Path $RepoRoot "pc-bridge"
$PubspecPath = Join-Path $AppDir "pubspec.yaml"
$ReleaseRoot = Join-Path $RepoRoot ".local\release"

function Invoke-Checked {
  param(
    [string]$FilePath,
    [string[]]$Arguments,
    [string]$WorkingDirectory = $RepoRoot
  )

  Push-Location $WorkingDirectory
  try {
    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) {
      throw "$FilePath exited with code $LASTEXITCODE"
    }
  } finally {
    Pop-Location
  }
}

function Find-AndroidBuildTool {
  param([string]$Name)

  $sdkRoot = $env:ANDROID_HOME
  if (-not $sdkRoot) {
    $sdkRoot = Join-Path $env:LOCALAPPDATA "Android\Sdk"
  }

  $tool = Get-ChildItem (Join-Path $sdkRoot "build-tools") -Recurse -Filter $Name -ErrorAction SilentlyContinue |
    Sort-Object FullName -Descending |
    Select-Object -First 1 -ExpandProperty FullName
  if (-not $tool) {
    throw "Android build tool was not found: $Name"
  }

  return $tool
}

function Assert-NotSensitiveArtifact {
  param([string]$Path)

  $name = Split-Path -Leaf $Path
  $blocked = @(
    "config.local.json",
    "key.properties",
    "google-services.json",
    "firebase-debug.log",
    "serviceAccount",
    ".env",
    ".keystore",
    ".jks"
  )

  foreach ($term in $blocked) {
    if ($name -like "*$term*") {
      throw "Refusing to include sensitive-looking artifact: $name"
    }
  }
}

$pubspec = Get-Content -LiteralPath $PubspecPath -Raw
if ($pubspec -notmatch "(?m)^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$") {
  throw "app/pubspec.yaml must contain version: <versionName>+<versionCode>"
}

$versionName = $Matches[1]
$versionCode = [int]$Matches[2]
if ($Version -and $Version -ne $versionName) {
  throw "Requested version $Version does not match app/pubspec.yaml versionName $versionName"
}
if ($PreviousVersionCode) {
  $previousCode = [int]$PreviousVersionCode
  if ($versionCode -le $previousCode) {
    throw "versionCode $versionCode must be greater than previous versionCode $previousCode"
  }
}

$releaseDir = Join-Path $ReleaseRoot $versionName
New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null

if (-not $SkipApkBuild) {
  if (-not (Test-Path (Join-Path $AppDir "android\key.properties"))) {
    throw "Missing app/android/key.properties. Create it before release APK build."
  }

  if (-not $NoClean) {
    Invoke-Checked -FilePath "flutter" -Arguments @("clean") -WorkingDirectory $AppDir
  }
  Invoke-Checked -FilePath "flutter" -Arguments @("pub", "get") -WorkingDirectory $AppDir
  Invoke-Checked -FilePath "flutter" -Arguments @("build", "apk", "--release") -WorkingDirectory $AppDir
}

$apkPath = Join-Path $AppDir "build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path -LiteralPath $apkPath)) {
  throw "Release APK was not found: $apkPath"
}

$apksigner = Find-AndroidBuildTool "apksigner.bat"
Invoke-Checked -FilePath $apksigner -Arguments @("verify", "--verbose", $apkPath)

$aapt = Find-AndroidBuildTool "aapt.exe"
$badging = & $aapt dump badging $apkPath
if ($LASTEXITCODE -ne 0) {
  throw "aapt dump badging failed."
}
if (($badging -join "`n") -notmatch "package: name='com\.sunmax\.remotecodex' versionCode='$versionCode' versionName='$versionName'") {
  throw "APK metadata does not match app/pubspec.yaml version/package."
}

$apkOut = Join-Path $releaseDir "RemoteCodex-$versionName.apk"
Copy-Item -LiteralPath $apkPath -Destination $apkOut -Force
Assert-NotSensitiveArtifact $apkOut

if (-not $SkipPcBridgePackage) {
  Invoke-Checked -FilePath "npm.cmd" -Arguments @("run", "package:dist") -WorkingDirectory $BridgeDir
}

$bridgeZip = Join-Path $BridgeDir ".local\distribution\codex-remote-pc-bridge.zip"
if (-not (Test-Path -LiteralPath $bridgeZip)) {
  throw "PC bridge distribution zip was not found: $bridgeZip"
}

$bridgeOut = Join-Path $releaseDir "codex-remote-pc-bridge-$versionName.zip"
Copy-Item -LiteralPath $bridgeZip -Destination $bridgeOut -Force
Assert-NotSensitiveArtifact $bridgeOut

$zipEntries = [System.IO.Compression.ZipFile]::OpenRead($bridgeOut)
try {
  foreach ($entry in $zipEntries.Entries) {
    $entryName = $entry.FullName
    foreach ($blocked in @("config.local.json", "node_modules/", "logs/", ".local/", "key.properties", ".env", ".jks", ".keystore", "serviceAccount")) {
      if ($entryName -like "*$blocked*") {
        throw "Sensitive or local-only file found in PC bridge zip: $entryName"
      }
    }
  }
} finally {
  $zipEntries.Dispose()
}

$hashPath = Join-Path $releaseDir "SHA256SUMS.txt"
$artifacts = @($apkOut, $bridgeOut)
$hashLines = foreach ($artifact in $artifacts) {
  $hash = Get-FileHash -Algorithm SHA256 -LiteralPath $artifact
  "$($hash.Hash)  $(Split-Path -Leaf $artifact)"
}
Set-Content -LiteralPath $hashPath -Value $hashLines -Encoding ascii

$releaseNotePath = Join-Path $releaseDir "release-notes-$versionName.md"
$commit = (& git -C $RepoRoot rev-parse HEAD).Trim()
$date = Get-Date -Format "yyyy-MM-dd"
$releaseNote = @"
# Codex Remote Android $versionName

## Summary

- Release date: $date
- Commit: $commit
- Android version: $versionName+$versionCode
- Android package: com.sunmax.remotecodex

## Artifacts

- RemoteCodex-$versionName.apk
- codex-remote-pc-bridge-$versionName.zip
- SHA256SUMS.txt

## Validation

- [ ] flutter test
- [ ] flutter analyze
- [ ] npm.cmd test in pc-bridge
- [ ] npm.cmd run check in pc-bridge
- [ ] apksigner verify --verbose
- [ ] aapt dump badging version/package check
- [ ] PC bridge zip inspection excludes config.local.json, logs, node_modules, .local, key material, and service account JSON
- [ ] Release E2E smoke evidence recorded

## Notes

- Do not upload key.properties, keystore/JKS files, service account JSON, config.local.json, logs, .env files, or google-services.json.
- Existing debug-signed installs may need uninstall before installing this release APK.
"@
Set-Content -LiteralPath $releaseNotePath -Value $releaseNote -Encoding utf8

$summary = [ordered]@{
  versionName = $versionName
  versionCode = $versionCode
  releaseDir = $releaseDir
  artifacts = @(
    (Split-Path -Leaf $apkOut),
    (Split-Path -Leaf $bridgeOut),
    (Split-Path -Leaf $hashPath),
    (Split-Path -Leaf $releaseNotePath)
  )
}

$summary | ConvertTo-Json -Depth 4
