type BridgeConfig = {
  pcBridgeId: string;
  displayName: string;
  workspaceName: string;
  workspacePath: string;
  firebaseProjectId: string;
  serviceAccountPath?: string;
};

function main(): void {
  const configPath = process.env.CODEX_REMOTE_BRIDGE_CONFIG ?? "config.local.json";

  console.log("Codex Remote PC Bridge scaffold");
  console.log(`Config path: ${configPath}`);
  console.log("Phase 4 will implement Firebase command listening and Codex invocation.");
}

main();

export type { BridgeConfig };

