import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import type { BridgeConfig, CodexMode, CodexSandbox, RelayMode } from "./types.js";

type RawConfig = Partial<BridgeConfig>;

export async function loadBridgeConfig(configPath: string): Promise<BridgeConfig> {
  const absolutePath = resolve(configPath);
  const rawText = await readFile(absolutePath, "utf8");
  const raw = JSON.parse(rawText) as RawConfig;

  return normalizeConfig(raw);
}

export function normalizeConfig(raw: RawConfig): BridgeConfig {
  const relayMode = raw.relayMode ?? "local";
  const codexMode = raw.codexMode ?? "stub";
  const codexSandbox = raw.codexSandbox ?? "workspace-write";

  if (!isRelayMode(relayMode)) {
    throw new Error(`Unsupported relayMode: ${String(relayMode)}`);
  }

  if (!isCodexMode(codexMode)) {
    throw new Error(`Unsupported codexMode: ${String(codexMode)}`);
  }

  if (!isCodexSandbox(codexSandbox)) {
    throw new Error(`Unsupported codexSandbox: ${String(codexSandbox)}`);
  }

  return {
    pcBridgeId: required(raw.pcBridgeId, "pcBridgeId"),
    displayName: required(raw.displayName, "displayName"),
    workspaceName: required(raw.workspaceName, "workspaceName"),
    workspacePath: required(raw.workspacePath, "workspacePath"),
    ownerUserId: raw.ownerUserId,
    firebaseProjectId: raw.firebaseProjectId,
    serviceAccountPath: raw.serviceAccountPath,
    relayMode,
    localRelayPath: raw.localRelayPath ?? ".local/relay-state.json",
    claimTtlSeconds: raw.claimTtlSeconds ?? 300,
    codexMode,
    codexCommandPath: raw.codexCommandPath ?? "codex.cmd",
    codexSandbox,
    codexTimeoutSeconds: raw.codexTimeoutSeconds ?? 900,
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

function isCodexMode(value: unknown): value is CodexMode {
  return value === "stub" || value === "cli";
}

function isCodexSandbox(value: unknown): value is CodexSandbox {
  return value === "read-only" || value === "workspace-write" || value === "danger-full-access";
}
