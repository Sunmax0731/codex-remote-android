import { loadBridgeConfig } from "./lib/config.js";
import { createAttachmentDownloader } from "./lib/attachmentDownloader.js";
import { createCodexInvoker } from "./lib/codexInvoker.js";
import { processNextCommand } from "./lib/processor.js";
import { createCommandRepository } from "./lib/relayRepository.js";

let shuttingDown = false;

process.on("SIGINT", () => {
  shuttingDown = true;
  console.log("Stopping PC bridge watcher...");
});

process.on("SIGTERM", () => {
  shuttingDown = true;
  console.log("Stopping PC bridge watcher...");
});

async function main(): Promise<void> {
  const configPath = process.env.CODEX_REMOTE_BRIDGE_CONFIG ?? "config.local.json";
  const config = await loadBridgeConfig(configPath);
  const repository = createCommandRepository(config);
  const invoker = createCodexInvoker(config);
  const attachmentDownloader = createAttachmentDownloader(config);
  const pollIntervalMs = Math.max(1, config.pollIntervalSeconds) * 1000;
  const heartbeatIntervalMs = Math.max(1, config.heartbeatIntervalSeconds) * 1000;
  const maxCommandsPerTick = Math.max(1, config.maxCommandsPerTick);

  console.log(`Config path: ${configPath}`);
  console.log(`Relay mode: ${config.relayMode}`);
  console.log(`PC bridge: ${config.pcBridgeId}`);
  console.log(`Polling every ${config.pollIntervalSeconds}s, up to ${maxCommandsPerTick} command(s) per tick.`);
  console.log(`Heartbeat every ${config.heartbeatIntervalSeconds}s.`);

  const heartbeat = startHeartbeatLoop({
    config,
    repository,
    intervalMs: heartbeatIntervalMs,
  });

  while (!shuttingDown) {
    try {
      await repository.updateQueueCheck(config.pcBridgeId, new Date());
      const respondedHealthChecks = await repository.respondPendingHealthChecks(config.pcBridgeId, new Date());

      if (respondedHealthChecks > 0) {
        console.log(`Responded to ${respondedHealthChecks} health check(s).`);
      }

      let processedCount = 0;

      for (let index = 0; index < maxCommandsPerTick && !shuttingDown; index += 1) {
        const result = await processNextCommand({
          config,
          repository,
          invoker,
          attachmentDownloader,
        });

        if (result.kind === "none") {
          break;
        }

        processedCount += 1;
        console.log(`Processed command ${result.commandId}: ${result.status}`);
      }

      if (processedCount === 0) {
        console.log(`No queued command found. Next poll in ${config.pollIntervalSeconds}s.`);
      }
    } catch (error: unknown) {
      console.error(error instanceof Error ? error.message : String(error));
    }

    if (!shuttingDown) {
      await sleep(pollIntervalMs);
    }
  }

  heartbeat.stop();
}

function sleep(milliseconds: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

function startHeartbeatLoop(input: {
  config: Awaited<ReturnType<typeof loadBridgeConfig>>;
  repository: ReturnType<typeof createCommandRepository>;
  intervalMs: number;
}): { stop: () => void } {
  let inFlight = false;

  const update = async (): Promise<void> => {
    if (inFlight) {
      return;
    }

    inFlight = true;
    try {
      await input.repository.updateHeartbeat(input.config.pcBridgeId, new Date());
    } catch (error: unknown) {
      console.error(error instanceof Error ? error.message : String(error));
    } finally {
      inFlight = false;
    }
  };

  void update();
  const timer = setInterval(() => {
    void update();
  }, input.intervalMs);

  return {
    stop: () => clearInterval(timer),
  };
}

main().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
});
