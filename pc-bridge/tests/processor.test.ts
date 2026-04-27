import test from "node:test";
import assert from "node:assert/strict";
import { normalizeConfig } from "../src/lib/config.js";
import { processNextCommand } from "../src/lib/processor.js";
import type { CodexInvoker, CommandClaim, CommandRepository, RemoteCommand } from "../src/lib/types.js";

test("processNextCommand completes claimed commands and redacts progress and result text", async () => {
  const repository = new MemoryCommandRepository(makeCommand());
  const invoker: CodexInvoker = {
    async invoke(input) {
      await input.onProgress?.(
        'working with "private_key":"-----BEGIN PRIVATE KEY-----abc-----END PRIVATE KEY-----"',
        new Date("2026-04-27T01:00:01.000Z"),
      );
      return {
        kind: "success",
        resultText: "done with AIza123456789012345678901234567890123456",
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
  const invoker: CodexInvoker = {
    async invoke() {
      return {
        kind: "failure",
        errorText: "failed with ghp_abcdefghijklmnopqrstuvwxyz1234567890",
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

function makeCommand(): RemoteCommand {
  return {
    userId: "userA",
    sessionId: "session1",
    commandId: "command1",
    text: "hello",
    status: "running",
    targetPcBridgeId: "pc-a",
    createdAt: "2026-04-27T00:00:00.000Z",
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
