param(
  [string]$DeviceId = "",
  [string]$PackageName = "com.sunmax.remotecodex",
  [string]$ApkPath = "app\build\app\outputs\flutter-apk\app-release.apk",
  [switch]$BuildDebug,
  [switch]$Install,
  [string]$EvidencePath = ""
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$AppDir = Join-Path $RepoRoot "app"

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

function Read-FlutterAndroidDevice {
  if ($DeviceId.Trim().Length -gt 0) {
    return $DeviceId
  }

  $devicesJson = & flutter devices --machine
  if ($LASTEXITCODE -ne 0) {
    throw "flutter devices --machine failed."
  }

  $devices = $devicesJson | ConvertFrom-Json
  $androidDevices = @($devices | Where-Object { $_.targetPlatform -like "android*" })
  if ($androidDevices.Count -eq 0) {
    throw "No Android device was found. Connect a physical device with USB or wireless debugging."
  }

  return $androidDevices[0].id
}

$ResolvedDeviceId = Read-FlutterAndroidDevice

if ($BuildDebug) {
  Invoke-Checked -FilePath "flutter" -Arguments @("build", "apk", "--debug") -WorkingDirectory $AppDir
  $ApkPath = "app\build\app\outputs\flutter-apk\app-debug.apk"
}

$ResolvedApkPath = Join-Path $RepoRoot $ApkPath

if ($Install) {
  if (-not (Test-Path -LiteralPath $ResolvedApkPath)) {
    throw "APK was not found: $ResolvedApkPath"
  }

  Invoke-Checked -FilePath "adb" -Arguments @("-s", $ResolvedDeviceId, "install", "-r", $ResolvedApkPath)
}

$DeviceInfo = [ordered]@{
  id = $ResolvedDeviceId
  model = (& adb -s $ResolvedDeviceId shell getprop ro.product.model).Trim()
  androidVersion = (& adb -s $ResolvedDeviceId shell getprop ro.build.version.release).Trim()
  sdk = (& adb -s $ResolvedDeviceId shell getprop ro.build.version.sdk).Trim()
}

$PackageInfoText = & adb -s $ResolvedDeviceId shell dumpsys package $PackageName
$PackageInfo = ($PackageInfoText -join "`n")
$PackageInstalled = $LASTEXITCODE -eq 0 -and $PackageInfo.Contains($PackageName)
$VersionName = $null
$VersionCode = $null
$VersionNameMatch = [regex]::Match($PackageInfo, "versionName=([^\s]+)")
if ($VersionNameMatch.Success) {
  $VersionName = $VersionNameMatch.Groups[1].Value
}
$VersionCodeMatch = [regex]::Match($PackageInfo, "versionCode=(\d+)")
if ($VersionCodeMatch.Success) {
  $VersionCode = $VersionCodeMatch.Groups[1].Value
}

$LogcatText = & adb -s $ResolvedDeviceId logcat -d -t 200 2>$null
$RemoteCodexLogTail = @($LogcatText | Select-String -Pattern "RemoteCodex|Flutter|FirebaseMessaging" -CaseSensitive:$false | Select-Object -Last 40 | ForEach-Object { $_.Line })

$Evidence = [ordered]@{
  generatedAt = (Get-Date).ToUniversalTime().ToString("o")
  device = $DeviceInfo
  package = [ordered]@{
    name = $PackageName
    installed = $PackageInstalled
    versionName = $VersionName
    versionCode = $VersionCode
  }
  apk = [ordered]@{
    path = $ResolvedApkPath
    exists = Test-Path -LiteralPath $ResolvedApkPath
    installedDuringRun = [bool]$Install
    builtDebugDuringRun = [bool]$BuildDebug
  }
  manualChecks = [ordered]@{
    firebaseSetupQrScanned = "fill after manual check"
    notificationPermission = "fill after manual check"
    sessionCreated = "fill after manual check"
    commandSent = "fill after manual check"
    commandCompletedOnDevice = "fill after manual check"
    notificationReceived = "fill after manual check"
  }
  logcatTail = $RemoteCodexLogTail
}

$Json = $Evidence | ConvertTo-Json -Depth 8

if ($EvidencePath.Trim().Length -gt 0) {
  $ResolvedEvidencePath = Join-Path $RepoRoot $EvidencePath
  $EvidenceDir = Split-Path -Parent $ResolvedEvidencePath
  if ($EvidenceDir -and -not (Test-Path -LiteralPath $EvidenceDir)) {
    New-Item -ItemType Directory -Force -Path $EvidenceDir | Out-Null
  }
  Set-Content -LiteralPath $ResolvedEvidencePath -Value $Json -Encoding utf8
}

$Json
