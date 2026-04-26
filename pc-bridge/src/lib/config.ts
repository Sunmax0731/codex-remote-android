import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import type { BridgeConfig, RelayMode } from "./types.js";

type RawConfig = Partial<BridgeConfig>;

export async function loadBridgeConfig(configPath: string): Promise<BridgeConfig> {
  const absolutePath = resolve(configPath);
  const rawText = await readFile(absolutePath, "utf8");
  const raw = JSON.parse(rawText) as RawConfig;

  return normalizeConfig(raw);
}

export function normalizeConfig(raw: RawConfig): BridgeConfig {
  const relayMode = raw.relayMode ?? "local";

  if (!isRelayMode(relayMode)) {
    throw new Error(`Unsupported relayMode: ${String(relayMode)}`);
  }

  return {
    pcBridgeId: required(raw.pcBridgeId, "pcBridgeId"),
    displayName: required(raw.displayName, "displayName"),
    workspaceName: required(raw.workspaceName, "workspaceName"),
    workspacePath: required(raw.workspacePath, "workspacePath"),
    firebaseProjectId: raw.firebaseProjectId,
    serviceAccountPath: raw.serviceAccountPath,
    relayMode,
    localRelayPath: raw.localRelayPath ?? ".local/relay-state.json",
    claimTtlSeconds: raw.claimTtlSeconds ?? 300,
  };
}

function required(value: string | undefined, field: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new Error(`Missing required bridge config field: ${field}`);
  }

  return value;
}

function isRelayMode(value: unknown): value is RelayMode {
  return value === "local" || value === "firestore";
}
