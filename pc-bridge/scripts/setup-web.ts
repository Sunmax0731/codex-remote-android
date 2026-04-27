import { createServer, type IncomingMessage, type ServerResponse } from "node:http";
import { access, readFile, readdir, stat } from "node:fs/promises";
import { constants } from "node:fs";
import { spawn } from "node:child_process";
import { extname, join, normalize, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { loadBridgeConfig } from "../src/lib/config.js";
import {
  buildFirebaseSetupPayload,
  firebaseSetupPayloadToDataUrl,
  parseGoogleServicesJson,
} from "../src/lib/firebaseSetupQr.js";
import { redactSensitiveText } from "../src/lib/redaction.js";

type GenerateRequest = {
  googleServicesJson?: string;
  packageName?: string;
};

const currentDir = fileURLToPath(new URL(".", import.meta.url));
const rootDir = resolve(currentDir, "..", "..");
const publicDir = join(rootDir, "setup-web");
const port = Number(process.env.CODEX_REMOTE_SETUP_PORT ?? 8787);

const contentTypes: Record<string, string> = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".svg": "image/svg+xml",
};

const server = createServer(async (request, response) => {
  try {
    if (request.method === "POST" && request.url === "/api/firebase-setup-qr") {
      await handleGenerateQr(request, response);
      return;
    }

    if (request.method === "GET" && request.url === "/api/pc-bridge/status") {
      await handleBridgeStatus(response);
      return;
    }

    if (request.method === "POST" && request.url === "/api/pc-bridge/start") {
      await handleBridgeStart(response);
      return;
    }

    if (request.method === "POST" && request.url === "/api/pc-bridge/register-task") {
      await handleBridgeRegisterTask(response);
      return;
    }

    if (request.method === "GET") {
      await serveStatic(request, response);
      return;
    }

    sendJson(response, 405, { error: "Method not allowed." });
  } catch (error) {
    sendJson(response, 500, {
      error: error instanceof Error ? error.message : String(error),
    });
  }
});

server.listen(port, "127.0.0.1", () => {
  console.log(`Codex Remote setup UI: http://127.0.0.1:${port}`);
});

async function handleGenerateQr(
  request: IncomingMessage,
  response: ServerResponse,
): Promise<void> {
  const body = (await readRequestBody(request)).trim();
  if (!body) {
    sendJson(response, 400, { error: "Request body is empty." });
    return;
  }

  const data = JSON.parse(body) as GenerateRequest;
  if (!data.googleServicesJson?.trim()) {
    sendJson(response, 400, { error: "google-services.json is required." });
    return;
  }

  const googleServices = parseGoogleServicesJson(data.googleServicesJson);
  const payload = buildFirebaseSetupPayload(
    googleServices,
    data.packageName?.trim() || undefined,
  );
  const qrDataUrl = await firebaseSetupPayloadToDataUrl(payload);

  sendJson(response, 200, { payload, qrDataUrl });
}

async function handleBridgeStatus(response: ServerResponse): Promise<void> {
  const configPath = resolve(process.env.CODEX_REMOTE_BRIDGE_CONFIG ?? "config.local.json");
  const report: Record<string, unknown> = {
    generatedAt: new Date().toISOString(),
    config: {
      path: maskPath(configPath),
      exists: await exists(configPath),
      valid: false,
    },
    process: await inspectBridgeProcess(),
    logs: await readLatestBridgeLog(),
  };

  try {
    const config = await loadBridgeConfig(configPath);
    const serviceAccountPathExists = config.serviceAccountPath
      ? await exists(config.serviceAccountPath)
      : false;

    report.config = {
      path: maskPath(configPath),
      exists: true,
      valid: true,
      relayMode: config.relayMode,
      codexMode: config.codexMode,
      pcBridgeId: maskId(config.pcBridgeId),
      firebaseProjectId: maskProjectId(config.firebaseProjectId),
      serviceAccountConfigured: typeof config.serviceAccountPath === "string" && config.serviceAccountPath.length > 0,
      serviceAccountPathExists,
      workspaceConfigured: config.workspacePath.length > 0,
      classification: classifyConfigState(null, serviceAccountPathExists),
    };
  } catch (error) {
    report.config = {
      path: maskPath(configPath),
      exists: await exists(configPath),
      valid: false,
      error: redactSensitiveText(error instanceof Error ? error.message : String(error)),
      classification: classifyConfigState(error, false),
    };
  }

  sendJson(response, 200, report);
}

async function handleBridgeStart(response: ServerResponse): Promise<void> {
  const scriptPath = join(rootDir, "scripts", "start-watch-background.bat");
  const child = spawn(scriptPath, {
    cwd: rootDir,
    detached: true,
    shell: false,
    stdio: "ignore",
    windowsHide: true,
  });
  child.unref();
  sendJson(response, 200, { started: true, script: "scripts/start-watch-background.bat" });
}

async function handleBridgeRegisterTask(response: ServerResponse): Promise<void> {
  const scriptPath = join(rootDir, "scripts", "register-watch-task.bat");
  const result = await runCommand(scriptPath, [], rootDir);
  sendJson(response, result.exitCode === 0 ? 200 : 500, {
    exitCode: result.exitCode,
    stdout: redactSensitiveText(result.stdout),
    stderr: redactSensitiveText(result.stderr),
  });
}

async function serveStatic(
  request: IncomingMessage,
  response: ServerResponse,
): Promise<void> {
  const requestUrl = new URL(request.url ?? "/", `http://127.0.0.1:${port}`);
  const pathname = requestUrl.pathname === "/" ? "/index.html" : requestUrl.pathname;
  const filePath = normalize(join(publicDir, decodeURIComponent(pathname)));

  if (!filePath.startsWith(publicDir)) {
    sendText(response, 403, "Forbidden");
    return;
  }

  try {
    const content = await readFile(filePath);
    response.writeHead(200, {
      "Content-Type": contentTypes[extname(filePath)] ?? "application/octet-stream",
      "Cache-Control": "no-store",
    });
    response.end(content);
  } catch {
    sendText(response, 404, "Not found");
  }
}

async function readRequestBody(request: IncomingMessage): Promise<string> {
  const chunks: Buffer[] = [];
  for await (const chunk of request) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
    if (Buffer.concat(chunks).byteLength > 2_000_000) {
      throw new Error("Request body is too large.");
    }
  }
  return Buffer.concat(chunks).toString("utf8");
}

function sendJson(
  response: ServerResponse,
  statusCode: number,
  body: unknown,
): void {
  response.writeHead(statusCode, {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
  });
  response.end(JSON.stringify(body));
}

function sendText(
  response: ServerResponse,
  statusCode: number,
  body: string,
): void {
  response.writeHead(statusCode, {
    "Content-Type": "text/plain; charset=utf-8",
    "Cache-Control": "no-store",
  });
  response.end(body);
}

async function inspectBridgeProcess(): Promise<Record<string, unknown>> {
  if (process.platform !== "win32") {
    return {
      supported: false,
      running: false,
      note: "Process inspection is currently implemented for Windows.",
    };
  }

  const result = await runCommand(
    "powershell.exe",
    [
      "-NoProfile",
      "-Command",
      "Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -match 'dist[\\\\/]+src[\\\\/]+watch.js|start:watch|run-watch.bat' } | Select-Object ProcessId,Name,CommandLine | ConvertTo-Json -Depth 4",
    ],
    rootDir,
  );

  if (result.exitCode !== 0) {
    return {
      supported: true,
      running: false,
      error: redactSensitiveText(result.stderr || result.stdout),
    };
  }

  const trimmed = result.stdout.trim();
  if (!trimmed) {
    return { supported: true, running: false, matches: [] };
  }

  const parsed = JSON.parse(trimmed) as unknown;
  const matches = (Array.isArray(parsed) ? parsed : [parsed]).filter(
    (entry) =>
      !String((entry as Record<string, unknown>).CommandLine ?? "").includes(
        "Get-CimInstance Win32_Process",
      ),
  );
  return {
    supported: true,
    running: matches.length > 0,
    matches: matches.map((entry) => redactProcessEntry(entry)),
  };
}

async function readLatestBridgeLog(): Promise<Record<string, unknown>> {
  const logsDir = join(rootDir, "logs");
  const entries = await readdir(logsDir).catch(() => []);
  const candidates = await Promise.all(
    entries
      .filter((entry) => /^pc-bridge-watch-.*\.log$/i.test(entry))
      .map(async (entry) => {
        const path = join(logsDir, entry);
        return { entry, path, stats: await stat(path) };
      }),
  );
  const latest = candidates.sort((a, b) => b.stats.mtimeMs - a.stats.mtimeMs)[0];
  if (!latest) {
    return { found: false };
  }

  const text = await readFile(latest.path, "utf8");
  return {
    found: true,
    file: latest.entry,
    updatedAt: latest.stats.mtime.toISOString(),
    redactedTail: tail(redactSensitiveText(text), 6000),
  };
}

function runCommand(command: string, args: string[], cwd: string): Promise<{ exitCode: number | null; stdout: string; stderr: string }> {
  return new Promise((resolveRun) => {
    const child = spawn(command, args, {
      cwd,
      shell: false,
      windowsHide: true,
      stdio: ["ignore", "pipe", "pipe"],
    });

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

async function exists(path: string): Promise<boolean> {
  try {
    await access(path, constants.F_OK);
    return true;
  } catch {
    return false;
  }
}

function redactProcessEntry(value: unknown): unknown {
  if (!value || typeof value !== "object") {
    return value;
  }

  const entry = value as Record<string, unknown>;
  return {
    processId: entry.ProcessId,
    name: entry.Name,
    commandLine: typeof entry.CommandLine === "string" ? redactSensitiveText(entry.CommandLine) : entry.CommandLine,
  };
}

function classifyConfigState(error: unknown, serviceAccountPathExists: boolean): string {
  if (!error) {
    return serviceAccountPathExists ? "ready" : "service-account-path-missing";
  }

  const message = error instanceof Error ? error.message : String(error);
  if (message.includes("ENOENT") || message.includes("no such file")) {
    return "config-file-missing";
  }
  if (message.includes("Missing required bridge config field")) {
    return "config-required-field-missing";
  }
  if (message.includes("Unsupported")) {
    return "config-value-unsupported";
  }
  if (message.includes("JSON")) {
    return "config-json-invalid";
  }
  return "config-error";
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

function tail(value: string, maxLength: number): string {
  return value.length <= maxLength ? value : `...${value.slice(value.length - maxLength + 3)}`;
}
