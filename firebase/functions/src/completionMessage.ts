import type { DocumentData } from "firebase-admin/firestore";

export type CompletionMessage = {
  title: string;
  body: string;
};

export function buildCompletionMessage(
  status: string,
  command: DocumentData,
  sessionId: string,
  commandId: string,
): CompletionMessage {
  const isCompleted = status === "completed";
  const previewSource = isCompleted ? command.resultText : command.errorText;
  const preview = compactPreview(previewSource);

  return {
    title: isCompleted ? "RemoteCodex completed" : "RemoteCodex failed",
    body: preview || `Session ${sessionId}, command ${commandId}`,
  };
}

export function compactPreview(value: unknown): string {
  if (typeof value !== "string") {
    return "";
  }

  const oneLine = redactSensitiveText(value).replace(/\s+/g, " ").trim();
  return oneLine.length <= 120 ? oneLine : `${oneLine.slice(0, 117)}...`;
}

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
