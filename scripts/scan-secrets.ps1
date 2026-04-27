param(
  [string[]]$Exclude = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$binaryExtensions = @(
  ".apk", ".aab", ".bin", ".dll", ".exe", ".ico", ".jar", ".jpg", ".jpeg",
  ".keystore", ".p12", ".png", ".so", ".webp", ".zip"
)

$patterns = @(
  @{ Name = "pem-private-key"; Regex = "-----BEGIN (RSA |DSA |EC |OPENSSH |)?PRIVATE KEY-----" },
  @{ Name = "json-private-key"; Regex = '"private_key"\s*:\s*"(?!\[REDACTED_)[^"]{20,}"' },
  @{ Name = "client-secret"; Regex = '"client_secret"\s*:\s*"(?!\[REDACTED_)[^"]{16,}"' },
  @{ Name = "refresh-token"; Regex = '"refresh_token"\s*:\s*"(?!\[REDACTED_)[^"]{16,}"' },
  @{ Name = "access-token"; Regex = '"access_token"\s*:\s*"(?!\[REDACTED_)[^"]{16,}"' },
  @{ Name = "github-token"; Regex = "gh[pousr]_[A-Za-z0-9_]{30,}" },
  @{ Name = "google-oauth-token"; Regex = "ya29\.[A-Za-z0-9_\-]+" },
  @{ Name = "slack-token"; Regex = "xox[baprs]-[A-Za-z0-9\-]{20,}" },
  @{ Name = "firebase-api-key"; Regex = "AIza[0-9A-Za-z_\-]{35}" }
)

$trackedFiles = & git -C $RepoRoot ls-files
if ($LASTEXITCODE -ne 0) {
  throw "git ls-files failed."
}

$findings = New-Object System.Collections.Generic.List[string]
foreach ($relativePath in $trackedFiles) {
  if (-not $relativePath) {
    continue
  }

  if ($Exclude -contains $relativePath) {
    continue
  }

  $extension = [System.IO.Path]::GetExtension($relativePath).ToLowerInvariant()
  if ($binaryExtensions -contains $extension) {
    continue
  }

  $fullPath = Join-Path $RepoRoot $relativePath
  if (-not (Test-Path -LiteralPath $fullPath)) {
    continue
  }

  try {
    $lines = @(Get-Content -LiteralPath $fullPath -ErrorAction Stop)
  } catch {
    continue
  }

  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    foreach ($pattern in $patterns) {
      if ($line -match $pattern.Regex) {
        $findings.Add("${relativePath}:$($i + 1): $($pattern.Name)")
      }
    }
  }
}

if ($findings.Count -gt 0) {
  $findings | ForEach-Object { Write-Error $_ }
  throw "Potential secret material was found in tracked files."
}

"No tracked secret-looking values were found."
