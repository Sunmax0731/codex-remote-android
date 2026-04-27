import test from "node:test";
import assert from "node:assert/strict";
import { normalizeConfig } from "../src/lib/config.js";
import { processNextCommand } from "../src/lib/processor.js";
import type {
  AttachmentDownloader,
  CodexInvoker,
  CommandClaim,
  CommandRepository,
  RemoteCommand,
} from "../src/lib/types.js";

test("processNextCommand completes claimed commands and redacts progress and result text", async () => {
  const repository = new MemoryCommandRepository(makeCommand());
  const privateKey = "-----BEGIN " + "PRIVATE KEY-----abc-----END " + "PRIVATE KEY-----";
  const firebaseApiKey = "AIza" + "123456789012345678901234567890123456";
  const invoker: CodexInvoker = {
    async invoke(input) {
      await input.onProgress?.(
        `working with "private_key":"${privateKey}"`,
        new Date("2026-04-27T01:00:01.000Z"),
      );
      return {
        kind: "success",
        resultText: `done with ${firebaseApiKey}`,
      };
    },
  };

  const result = await processNextCommand({
    config: testConfig(),
    repository,
    invoker,
    now: new Date("2026-04-27T01:00:00.000Z"),
  });

  assert.deepEqual(result, { kind: "processed", commandId: "command1", status: "completed" });
  assert.equal(repository.completed?.resultText, "done with [REDACTED_FIREBASE_API_KEY]");
  assert.equal(
    repository.progress[0]?.progressText,
    'working with "private_key":"[REDACTED_PRIVATE_KEY]"',
  );
});

test("processNextCommand marks invoker failures as failed and redacts error text", async () => {
  const repository = new MemoryCommandRepository(makeCommand());
  const githubToken = "ghp_" + "abcdefghijklmnopqrstuvwxyz1234567890";
  const invoker: CodexInvoker = {
    async invoke() {
      return {
        kind: "failure",
        errorText: `failed with ${githubToken}`,
      };
    },
  };

  const result = await processNextCommand({
    config: testConfig(),
    repository,
    invoker,
    now: new Date("2026-04-27T01:00:00.000Z"),
  });

  assert.deepEqual(result, { kind: "processed", commandId: "command1", status: "failed" });
  assert.equal(repository.failed?.errorText, "failed with [REDACTED_GITHUB_TOKEN]");
});

test("processNextCommand prepares attachments before invoking Codex and cleans up", async () => {
  const command = makeCommand({
    attachments: [
      {
        id: "att_1_0",
        type: "file",
        fileName: "notes.md",
        contentType: "text/markdown",
        sizeBytes: 4,
        storagePath: "users/userA/sessions/session1/commands/command1/attachments/att_1_0/notes.md",
        sha256: "a".repeat(64),
      },
    ],
  });
  const repository = new MemoryCommandRepository(command);
  let cleaned = false;
  const attachmentDownloader: AttachmentDownloader = {
    async prepare(inputCommand) {
      return {
        command: {
          ...inputCommand,
          text: `${inputCommand.text}\n\nAttached files:\n- notes.md: D:\\cache\\notes.md`,
          codexAddDirs: ["D:\\cache"],
        },
        async cleanup() {
          cleaned = true;
        },
      };
    },
  };
  const invoker: CodexInvoker = {
    async invoke(input) {
      assert.match(input.command.text, /Attached files/);
      assert.deepEqual(input.command.codexAddDirs, ["D:\\cache"]);
      return {
        kind: "success",
        resultText: "done",
      };
    },
  };

  const result = await processNextCommand({
    config: testConfig(),
    repository,
    invoker,
    attachmentDownloader,
    now: new Date("2026-04-27T01:00:00.000Z"),
  });

  assert.deepEqual(result, { kind: "processed", commandId: "command1", status: "completed" });
  assert.equal(cleaned, true);
});

test("processNextCommand returns none when no command is claimable", async () => {
  const repository = new MemoryCommandRepository(null);
  const invoker: CodexInvoker = {
    async invoke() {
      throw new Error("invoker should not be called");
    },
  };

  const result = await processNextCommand({
    config: testConfig(),
    repository,
    invoker,
    now: new Date("2026-04-27T01:00:00.000Z"),
  });

  assert.deepEqual(result, { kind: "none" });
});

function testConfig() {
  return normalizeConfig({
    pcBridgeId: "pc-a",
    displayName: "PC A",
    workspaceName: "test",
    workspacePath: "D:\\test",
    relayMode: "local",
    localRelayPath: ".local\\relay-state.json",
    claimTtlSeconds: 300,
  });
}

function makeCommand(overrides: Partial<RemoteCommand> = {}): RemoteCommand {
  return {
    userId: "userA",
    sessionId: "session1",
    commandId: "command1",
    text: "hello",
    status: "running",
    targetPcBridgeId: "pc-a",
    createdAt: "2026-04-27T00:00:00.000Z",
    ...overrides,
  };
}

class MemoryCommandRepository implements CommandRepository {
  progress: Array<{ progressText: string; claimTtlSeconds: number }> = [];
  completed?: { resultText: string };
  failed?: { errorText: string };

  constructor(private readonly command: RemoteCommand | null) {}

  async claimNextQueuedCommand(): Promise<RemoteCommand | null> {
    return this.command;
  }

  async updateProgress(_claim: CommandClaim, progressText: string, _now: Date, claimTtlSeconds: number): Promise<void> {
    this.progress.push({ progressText, claimTtlSeconds });
  }

  async markCompleted(_claim: CommandClaim, resultText: string): Promise<void> {
    this.completed = { resultText };
  }

  async markFailed(_claim: CommandClaim, errorText: string): Promise<void> {
    this.failed = { errorText };
  }

  async updateHeartbeat(): Promise<void> {}

  async updateQueueCheck(): Promise<void> {}

  async respondPendingHealthChecks(): Promise<number> {
    return 0;
  }
}
