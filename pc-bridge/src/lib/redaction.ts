export function redactSensitiveText(value: string): string {
  return value
    .replace(/-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----/g, "[REDACTED_PRIVATE_KEY]")
    .replace(/("private_key"\s*:\s*")([^"]+)(")/g, "$1[REDACTED_PRIVATE_KEY]$3")
    .replace(/("client_secret"\s*:\s*")([^"]+)(")/g, "$1[REDACTED_CLIENT_SECRET]$3")
    .replace(/("refresh_token"\s*:\s*")([^"]+)(")/g, "$1[REDACTED_REFRESH_TOKEN]$3")
    .replace(/("access_token"\s*:\s*")([^"]+)(")/g, "$1[REDACTED_ACCESS_TOKEN]$3")
    .replace(/AIza[0-9A-Za-z_-]{20,}/g, "[REDACTED_FIREBASE_API_KEY]")
    .replace(/ya29\.[0-9A-Za-z._-]+/g, "[REDACTED_GOOGLE_ACCESS_TOKEN]")
    .replace(/github_pat_[0-9A-Za-z_]+/g, "[REDACTED_GITHUB_TOKEN]")
    .replace(/ghp_[0-9A-Za-z_]{30,}/g, "[REDACTED_GITHUB_TOKEN]")
    .replace(/xox[baprs]-[0-9A-Za-z-]+/g, "[REDACTED_SLACK_TOKEN]");
}
