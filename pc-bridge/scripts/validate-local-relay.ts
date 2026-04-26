import { mkdtemp, readFile, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { normalizeConfig } from "../src/lib/config.js";
import { createCodexInvoker } from "../src/lib/codexInvoker.js";
import { LocalRelayRepository } from "../src/lib/localRelayRepository.js";
import { processNextCommand } from "../src/lib/processor.js";

const tempRoot = await mkdtemp(join(tmpdir(), "codex-remote-bridge-"));
const relayPath = join(tempRoot, "relay-state.json");

const config = normalizeConfig({
  pcBridgeId: "home-main-pc",
  displayName: "Home PC",
  workspaceName: "codex-remote-android",
  workspacePath: "D:\\Claude\\FlutterApp\\codex-remote-android",
  relayMode: "local",
  localRelayPath: relayPath,
  claimTtlSeconds: 300,
});

await writeFile(
  relayPath,
  `${JSON.stringify(
    {
      users: {
        userA: {
          pcBridges: {
            "home-main-pc": {
              displayName: "Home PC",
              status: "inactive",
            },
          },
          sessions: {
            session1: {
              status: "queued",
              targetPcBridgeId: "home-main-pc",
              commands: {
                command1: {
                  text: "READMEを確認してください",
                  status: "queued",
                  targetPcBridgeId: "home-main-pc",
                  createdAt: "2026-04-26T00:00:00.000Z",
                },
              },
            },
            session2: {
              status: "queued",
              targetPcBridgeId: "home-main-pc",
              commands: {
                command2: {
                  text: "/fail validation",
                  status: "queued",
                  targetPcBridgeId: "home-main-pc",
                  createdAt: "2026-04-26T00:00:00.000Z",
                },
              },
            },
          },
        },
      },
    },
    null,
    2,
  )}\n`,
  "utf8",
);

const repository = new LocalRelayRepository(relayPath);
const invoker = createCodexInvoker(config);

const first = await processNextCommand({ config, repository, invoker });
assert(first.kind === "processed" && first.commandId === "command1" && first.status === "completed", "first command");

const second = await processNextCommand({ config, repository, invoker });
assert(second.kind === "processed" && second.commandId === "command2" && second.status === "failed", "second command");

const third = await processNextCommand({ config, repository, invoker });
assert(third.kind === "none", "no command remains");

const state = JSON.parse(await readFile(relayPath, "utf8")) as {
  users: {
    userA: {
      sessions: {
        session1: { commands: { command1: { status: string; resultText?: string } } };
        session2: { commands: { command2: { status: string; errorText?: string } } };
      };
    };
  };
};

assert(state.users.userA.sessions.session1.commands.command1.status === "completed", "command1 completed");
assert(typeof state.users.userA.sessions.session1.commands.command1.resultText === "string", "command1 result");
assert(state.users.userA.sessions.session2.commands.command2.status === "failed", "command2 failed");
assert(typeof state.users.userA.sessions.session2.commands.command2.errorText === "string", "command2 error");

console.log("Local relay lifecycle validation passed.");

function assert(condition: boolean, label: string): void {
  if (!condition) {
    throw new Error(`Validation failed: ${label}`);
  }
}
