import { loadBridgeConfig } from "./lib/config.js";
import { createCodexInvoker } from "./lib/codexInvoker.js";
import { processNextCommand } from "./lib/processor.js";
import { createCommandRepository } from "./lib/relayRepository.js";

async function main(): Promise<void> {
  const configPath = process.env.CODEX_REMOTE_BRIDGE_CONFIG ?? "config.local.json";
  const config = await loadBridgeConfig(configPath);
  const repository = createCommandRepository(config);
  const invoker = createCodexInvoker(config);

  console.log(`Config path: ${configPath}`);
  console.log(`Relay mode: ${config.relayMode}`);
  console.log(`PC bridge: ${config.pcBridgeId}`);

  await repository.updateHeartbeat(config.pcBridgeId, new Date());
  await repository.updateQueueCheck(config.pcBridgeId, new Date());

  const result = await processNextCommand({
    config,
    repository,
    invoker,
  });

  if (result.kind === "none") {
    console.log("No queued command found.");
    return;
  }

  console.log(`Processed command ${result.commandId}: ${result.status}`);
}

main().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
});

