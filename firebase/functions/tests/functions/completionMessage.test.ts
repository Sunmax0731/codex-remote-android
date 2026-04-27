import test from "node:test";
import assert from "node:assert/strict";
import { buildCompletionMessage, compactPreview, redactSensitiveText } from "../../src/completionMessage.js";

test("buildCompletionMessage uses completed result preview", () => {
  const message = buildCompletionMessage(
    "completed",
    { resultText: "line 1\nline 2" },
    "sessionA",
    "commandA",
  );

  assert.deepEqual(message, {
    title: "RemoteCodex completed",
    body: "line 1 line 2",
  });
});

test("buildCompletionMessage uses failed error preview and redacts secrets", () => {
  const message = buildCompletionMessage(
    "failed",
    { errorText: "failed with ghp_abcdefghijklmnopqrstuvwxyz1234567890" },
    "sessionA",
    "commandA",
  );

  assert.deepEqual(message, {
    title: "RemoteCodex failed",
    body: "failed with [REDACTED_GITHUB_TOKEN]",
  });
});

test("buildCompletionMessage falls back to session and command when preview is missing", () => {
  const message = buildCompletionMessage("completed", {}, "sessionA", "commandA");

  assert.deepEqual(message, {
    title: "RemoteCodex completed",
    body: "Session sessionA, command commandA",
  });
});

test("compactPreview truncates after redaction and whitespace compaction", () => {
  const preview = compactPreview(`${"x ".repeat(90)}AIza123456789012345678901234567890123456`);

  assert.equal(preview.length, 120);
  assert.ok(preview.endsWith("..."));
  assert.ok(!preview.includes("AIza"));
});

test("redactSensitiveText redacts Firebase and service account secrets", () => {
  const redacted = redactSensitiveText(
    [
      '"private_key":"-----BEGIN PRIVATE KEY-----abc-----END PRIVATE KEY-----"',
      '"client_secret":"secret-value"',
      "ya29.a0AfH6SMBtoken",
      "AIza123456789012345678901234567890123456",
    ].join("\n"),
  );

  assert.ok(redacted.includes("[REDACTED_PRIVATE_KEY]"));
  assert.ok(redacted.includes("[REDACTED_CLIENT_SECRET]"));
  assert.ok(redacted.includes("[REDACTED_GOOGLE_ACCESS_TOKEN]"));
  assert.ok(redacted.includes("[REDACTED_FIREBASE_API_KEY]"));
  assert.ok(!redacted.includes("secret-value"));
  assert.ok(!redacted.includes("AIza1234567890"));
});
