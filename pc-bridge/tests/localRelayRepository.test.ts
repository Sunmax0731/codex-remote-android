import { mkdtemp, readFile, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import assert from "node:assert/strict";
import { LocalRelayRepository } from "../src/lib/localRelayRepository.js";

test("claimNextQueuedCommand claims only matching queued commands", async () => {
  const relayPath = await createRelayState({
    commandA: {
      text: "run A",
      status: "queued",
      targetPcBridgeId: "pc-a",
      createdAt: "2026-04-27T00:00:00.000Z",
    },
    commandB: {
      text: "run B",
      status: "queued",
      targetPcBridgeId: "pc-b",
      createdAt: "2026-04-27T00:00:00.000Z",
    },
  });
  const repository = new LocalRelayRepository(relayPath);
  const now = new Date("2026-04-27T01:00:00.000Z");

  const claimed = await repository.claimNextQueuedCommand("pc-a", now, 300);

  assert.equal(claimed?.commandId, "commandA");
  assert.equal(claimed?.status, "running");

  const state = await readRelayState(relayPath);
  const commandA = state.users.userA.sessions.session1.commands.commandA;
  const commandB = state.users.userA.sessions.session1.commands.commandB;

  assert.equal(commandA.status, "running");
  assert.equal(commandA.claimedByPcBridgeId, "pc-a");
  assert.equal(commandA.claimedAt, "2026-04-27T01:00:00.000Z");
  assert.equal(commandA.claimExpiresAt, "2026-04-27T01:05:00.000Z");
  assert.equal(commandB.status, "queued");
});

test("claimNextQueuedCommand reclaims expired running commands", async () => {
  const relayPath = await createRelayState({
    commandExpired: {
      text: "retry me",
      status: "running",
      targetPcBridgeId: "pc-a",
      createdAt: "2026-04-27T00:00:00.000Z",
      claimedByPcBridgeId: "pc-a",
      claimExpiresAt: "2026-04-27T00:59:59.000Z",
    },
  });
  const repository = new LocalRelayRepository(relayPath);

  const claimed = await repository.claimNextQueuedCommand("pc-a", new Date("2026-04-27T01:00:00.000Z"), 120);

  assert.equal(claimed?.commandId, "commandExpired");
  assert.equal(claimed?.claimExpiresAt, "2026-04-27T01:02:00.000Z");
});

test("claimNextQueuedCommand ignores active running commands", async () => {
  const relayPath = await createRelayState({
    commandActive: {
      text: "already running",
      status: "running",
      targetPcBridgeId: "pc-a",
      createdAt: "2026-04-27T00:00:00.000Z",
      claimedByPcBridgeId: "pc-a",
      claimExpiresAt: "2026-04-27T01:05:00.000Z",
    },
  });
  const repository = new LocalRelayRepository(relayPath);

  const claimed = await repository.claimNextQueuedCommand("pc-a", new Date("2026-04-27T01:00:00.000Z"), 120);

  assert.equal(claimed, null);
});

async function createRelayState(commands: Record<string, Record<string, unknown>>): Promise<string> {
  const tempRoot = await mkdtemp(join(tmpdir(), "codex-remote-bridge-test-"));
  const relayPath = join(tempRoot, "relay-state.json");
  const state = {
    users: {
      userA: {
        sessions: {
          session1: {
            status: "queued",
            targetPcBridgeId: "pc-a",
            commands,
          },
        },
      },
    },
  };

  await writeFile(relayPath, `${JSON.stringify(state, null, 2)}\n`, "utf8");
  return relayPath;
}

async function readRelayState(relayPath: string): Promise<{
  users: {
    userA: {
      sessions: {
        session1: {
          commands: Record<string, Record<string, unknown>>;
        };
      };
    };
  };
}> {
  return JSON.parse(await readFile(relayPath, "utf8"));
}
