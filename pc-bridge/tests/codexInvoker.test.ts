import test from "node:test";
import assert from "node:assert/strict";
import { cliErrorText } from "../src/lib/codexInvoker.js";

test("cliErrorText removes Cloudflare HTML noise and keeps the fallback", () => {
  const errorText = cliErrorText(
    {
      exitCode: 1,
      stdout: "",
      stderr: [
        "2026-04-27T11:39:36.363697Z  WARN codex_core::plugins::manager: failed to warm featured plugin ids cache error=remote plugin sync request to https://chatgpt.com/backend-api/plugins/featured failed with status 403 Forbidden: <html>",
        "<html>",
        "<body>",
        "<script>window._cf_chl_opt = { cZone: 'chatgpt.com' };</script>",
        "2026-04-27T11:40:44.000000Z ERROR codex_core::session: failed to record rollout items: thread missing",
      ].join("\n"),
    },
    "Codex CLI completed without a final message.",
  );

  assert.match(errorText, /^Codex CLI completed without a final message\./);
  assert.match(errorText, /failed to record rollout items/);
  assert.doesNotMatch(errorText, /window\._cf_chl_opt/);
  assert.doesNotMatch(errorText, /<html>/);
});

test("cliErrorText truncates very long remaining details", () => {
  const errorText = cliErrorText(
    {
      exitCode: 1,
      stdout: "",
      stderr: "x".repeat(5000),
    },
    "Codex CLI failed.",
  );

  assert.ok(errorText.length < 4100);
  assert.match(errorText, /\.\.\.\[truncated\]$/);
});
