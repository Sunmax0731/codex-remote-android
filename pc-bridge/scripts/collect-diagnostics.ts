import { access, readFile, readdir, stat } from "node:fs/promises";
import { constants } from "node:fs";
import { join, resolve } from "node:path";
import { spawn } from "node:child_process";
import { loadBridgeConfig } from "../src/lib/config.js";
import { redactSensitiveText } from "../src/lib/redaction.js";

type DiagnosticReport = {
  generatedAt: string;
  pcBridge: {
    packageVersion: string;
    nodeVersion: string;
    platform: string;
    arch: string;
  };
  config: {
    path: string;
    valid: boolean;
    error?: string;
    relayMode?: string;
    codexMode?: string;
    codexSandbox?: string;
    pcBridgeId?: string;
    ownerUserId?: string;
    firebaseProjectId?: string;
    serviceAccountConfigured?: boolean;
    serviceAccountPathExists?: boolean;
    workspaceConfigured?: boolean;
    localRelayConfigured?: boolean;
  };
  codexCli: {
    commandPath?: string;
    detected: boolean;
    version?: string;
    error?: string;
  };
  logs: {
    latestLogFile?: string;
    latestLogUpdatedAt?: string;
    redactedTail?: string;
  };
  notes: string[];
};

const configPath = process.env.CODEX_REMOTE_BRIDGE_CONFIG ?? "config.local.json";

const report: DiagnosticReport = {
  generatedAt: new Date().toISOString(),
  pcBridge: {
    packageVersion: await readPackageVersion(),
    nodeVersion: process.version,
    platform: process.platform,
    arch: process.arch,
  },
  config: {
    path: maskPath(resolve(configPath)),
    valid: false,
  },
  codexCli: {
    detected: false,
  },
  logs: {},
  notes: [
    "Do not attach config.local.json, service account JSON, google-services.json, tokens, private keys, or unredacted logs.",
    "Review this output before sharing it in a public GitHub Issue.",
  ],
};

try {
  const config = await loadBridgeConfig(configPath);
  const serviceAccountPathExists = config.serviceAccountPath
    ? await exists(config.serviceAccountPath)
    : false;

  report.config = {
    ...report.config,
    valid: true,
    relayMode: config.relayMode,
    codexMode: config.codexMode,
    codexSandbox: config.codexSandbox,
    pcBridgeId: maskId(config.pcBridgeId),
    ownerUserId: maskId(config.ownerUserId),
    firebaseProjectId: maskProjectId(config.firebaseProjectId),
    serviceAccountConfigured: typeof config.serviceAccountPath === "string" && config.serviceAccountPath.length > 0,
    serviceAccountPathExists,
    workspaceConfigured: config.workspacePath.length > 0,
    localRelayConfigured: config.localRelayPath.length > 0,
  };

  report.codexCli = await inspectCodexCli(config.codexCommandPath);
} catch (error) {
  report.config.error = error instanceof Error ? error.message : String(error);
}

report.logs = await readLatestLogTail();

console.log(JSON.stringify(report, null, 2));

async function readPackageVersion(): Promise<string> {
  const packageText = await readFile("package.json", "utf8");
  const packageJson = JSON.parse(packageText) as { version?: string };
  return packageJson.version ?? "unknown";
}

async function inspectCodexCli(commandPath: string): Promise<DiagnosticReport["codexCli"]> {
  const result = await runCommand(commandPath, ["--version"]);
  return {
    commandPath: maskPath(commandPath),
    detected: result.exitCode === 0,
    version: result.exitCode === 0 ? redactSensitiveText(result.stdout.trim()) : undefined,
    error: result.exitCode === 0 ? undefined : redactSensitiveText((result.stderr || result.stdout).trim()),
  };
}

function runCommand(commandPath: string, args: string[]): Promise<{ exitCode: number | null; stdout: string; stderr: string }> {
  return new Promise((resolveRun) => {
    const launch = process.platform === "win32" && /\.(cmd|bat)$/i.test(commandPath)
      ? { command: "cmd.exe", args: ["/d", "/s", "/c", commandPath, ...args] }
      : { command: commandPath, args };
    let child;

    try {
      child = spawn(launch.command, launch.args, {
        shell: false,
        windowsHide: true,
        stdio: ["ignore", "pipe", "pipe"],
      });
    } catch (error) {
      resolveRun({
        exitCode: 1,
        stdout: "",
        stderr: error instanceof Error ? error.message : String(error),
      });
      return;
    }

    let stdout = "";
    let stderr = "";

    child.stdout.setEncoding("utf8");
    child.stderr.setEncoding("utf8");
    child.stdout.on("data", (chunk: string) => {
      stdout += chunk;
    });
    child.stderr.on("data", (chunk: string) => {
      stderr += chunk;
    });
    child.on("error", (error) => {
      resolveRun({ exitCode: 1, stdout, stderr: stderr + error.message });
    });
    child.on("close", (exitCode) => {
      resolveRun({ exitCode, stdout, stderr });
    });
  });
}

async function readLatestLogTail(): Promise<DiagnosticReport["logs"]> {
  const logsDir = resolve("logs");
  const entries = await readdir(logsDir).catch(() => []);
  const candidates = await Promise.all(
    entries
      .filter((entry) => /^pc-bridge-watch-.*\.log$/i.test(entry))
      .map(async (entry) => {
        const path = join(logsDir, entry);
        return {
          entry,
          path,
          stats: await stat(path),
        };
      }),
  );
  const latest = candidates.sort((a, b) => b.stats.mtimeMs - a.stats.mtimeMs)[0];

  if (!latest) {
    return {};
  }

  const text = await readFile(latest.path, "utf8");
  return {
    latestLogFile: latest.entry,
    latestLogUpdatedAt: latest.stats.mtime.toISOString(),
    redactedTail: tail(redactSensitiveText(text), 4000),
  };
}

async function exists(path: string): Promise<boolean> {
  try {
    await access(path, constants.F_OK);
    return true;
  } catch {
    return false;
  }
}

function tail(value: string, maxLength: number): string {
  return value.length <= maxLength ? value : `...${value.slice(value.length - maxLength + 3)}`;
}

function maskId(value: string | undefined): string | undefined {
  if (!value) {
    return undefined;
  }

  return value.length <= 8 ? "***" : `${value.slice(0, 4)}...${value.slice(-4)}`;
}

function maskProjectId(value: string | undefined): string | undefined {
  if (!value) {
    return undefined;
  }

  const [prefix] = value.split("-");
  return `${prefix}-***`;
}

function maskPath(value: string): string {
  const normalized = value.replace(/\\/g, "/");
  const parts = normalized.split("/").filter((part) => part.length > 0);
  return parts.length <= 2 ? normalized : `.../${parts.slice(-2).join("/")}`;
}
