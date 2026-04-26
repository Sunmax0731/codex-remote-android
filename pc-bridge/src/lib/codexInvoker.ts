import { mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawn } from "node:child_process";
import type { BridgeConfig, CodexInvocation, CodexInvocationResult, CodexInvoker } from "./types.js";

export function createCodexInvoker(_config: BridgeConfig): CodexInvoker {
  if (_config.codexMode === "cli") {
    return new CliCodexInvoker(_config);
  }

  return new SafeStubCodexInvoker();
}

export class SafeStubCodexInvoker implements CodexInvoker {
  async invoke(input: CodexInvocation): Promise<CodexInvocationResult> {
    const text = input.command.text.trim();

    if (text.length === 0) {
      return {
        kind: "failure",
        errorText: "空の指示は処理できません。",
      };
    }

    if (text.startsWith("/fail")) {
      return {
        kind: "failure",
        errorText: "検証用の失敗指示として処理しました。",
      };
    }

    return {
      kind: "success",
      resultText: [
        "PCブリッジが指示を受け取りました。",
        `workspace: ${input.workspacePath}`,
        `commandId: ${input.command.commandId}`,
      ].join("\n"),
    };
  }
}

export class CliCodexInvoker implements CodexInvoker {
  private readonly config: BridgeConfig;

  constructor(config: BridgeConfig) {
    this.config = config;
  }

  async invoke(input: CodexInvocation): Promise<CodexInvocationResult> {
    const prompt = input.command.text.trim();

    if (prompt.length === 0) {
      return {
        kind: "failure",
        errorText: "空の指示は処理できません。",
      };
    }

    const tempRoot = await mkdtemp(join(tmpdir(), "codex-remote-cli-"));
    const outputPath = join(tempRoot, "last-message.txt");

    try {
      const result = await runCodexExec({
        commandPath: this.config.codexCommandPath,
        model: input.command.codexModel ?? this.config.codexModel,
        profile: input.command.codexProfile,
        configOverrides: input.command.codexConfigOverrides ?? [],
        enableFeatures: input.command.codexEnableFeatures ?? [],
        disableFeatures: input.command.codexDisableFeatures ?? [],
        images: input.command.codexImages ?? [],
        oss: input.command.codexOss ?? false,
        localProvider: input.command.codexLocalProvider,
        bypassSandbox: input.command.codexBypassSandbox ?? this.config.codexBypassSandbox,
        fullAuto: input.command.codexFullAuto ?? false,
        workspacePath: this.config.workspacePath,
        addDirs: input.command.codexAddDirs ?? [],
        sandbox: input.command.codexSandbox ?? this.config.codexSandbox,
        skipGitRepoCheck: input.command.codexSkipGitRepoCheck ?? false,
        ephemeral: input.command.codexEphemeral ?? false,
        ignoreUserConfig: input.command.codexIgnoreUserConfig ?? false,
        ignoreRules: input.command.codexIgnoreRules ?? false,
        outputSchema: input.command.codexOutputSchema,
        json: input.command.codexJson ?? false,
        timeoutSeconds: this.config.codexTimeoutSeconds,
        progressIntervalSeconds: this.config.codexProgressIntervalSeconds,
        outputPath,
        prompt,
        onProgress: input.onProgress,
      });

      if (result.exitCode !== 0) {
        return {
          kind: "failure",
          errorText: cliErrorText(result, `Codex CLI failed with exit code ${result.exitCode}.`),
        };
      }

      const output = await readFile(outputPath, "utf8").catch(() => "");
      const finalMessage = output.trim();

      if (!finalMessage) {
        return {
          kind: "failure",
          errorText: cliErrorText(result, "Codex CLI completed without a final message."),
        };
      }

      return {
        kind: "success",
        resultText: finalMessage,
      };
    } finally {
      await rm(tempRoot, { recursive: true, force: true });
    }
  }
}

type RunCodexExecInput = {
  commandPath: string;
  model?: string;
  profile?: string;
  configOverrides: string[];
  enableFeatures: string[];
  disableFeatures: string[];
  images: string[];
  oss: boolean;
  localProvider?: string;
  bypassSandbox: boolean;
  fullAuto: boolean;
  workspacePath: string;
  addDirs: string[];
  sandbox: string;
  skipGitRepoCheck: boolean;
  ephemeral: boolean;
  ignoreUserConfig: boolean;
  ignoreRules: boolean;
  outputSchema?: string;
  json: boolean;
  timeoutSeconds: number;
  progressIntervalSeconds: number;
  outputPath: string;
  prompt: string;
  onProgress?: (progressText: string, now: Date) => Promise<void>;
};

type RunCodexExecResult = {
  exitCode: number | null;
  stdout: string;
  stderr: string;
};

function runCodexExec(input: RunCodexExecInput): Promise<RunCodexExecResult> {
  const codexArgs = ["exec", "--cd", input.workspacePath];

  if (input.ignoreUserConfig) {
    codexArgs.push("--ignore-user-config");
  }

  for (const value of input.configOverrides) {
    codexArgs.push("--config", value);
  }

  for (const feature of input.enableFeatures) {
    codexArgs.push("--enable", feature);
  }

  for (const feature of input.disableFeatures) {
    codexArgs.push("--disable", feature);
  }

  for (const image of input.images) {
    codexArgs.push("--image", image);
  }

  if (input.bypassSandbox) {
    codexArgs.push("--dangerously-bypass-approvals-and-sandbox");
  } else if (input.fullAuto) {
    codexArgs.push("--full-auto");
  } else {
    codexArgs.push("--sandbox", input.sandbox);
  }

  if (input.oss) {
    codexArgs.push("--oss");
  }

  if (input.localProvider) {
    codexArgs.push("--local-provider", input.localProvider);
  }

  for (const addDir of input.addDirs) {
    codexArgs.push("--add-dir", addDir);
  }

  if (input.skipGitRepoCheck) {
    codexArgs.push("--skip-git-repo-check");
  }

  if (input.ephemeral) {
    codexArgs.push("--ephemeral");
  }

  if (input.ignoreRules) {
    codexArgs.push("--ignore-rules");
  }

  if (input.outputSchema) {
    codexArgs.push("--output-schema", input.outputSchema);
  }

  if (input.json) {
    codexArgs.push("--json");
  }

  codexArgs.push("--output-last-message", input.outputPath, "-");

  if (input.model) {
    codexArgs.splice(1, 0, "-m", input.model);
  }

  if (input.profile) {
    codexArgs.splice(1, 0, "-p", input.profile);
  }

  return new Promise((resolve) => {
    const launch = resolveLaunchCommand(input.commandPath, codexArgs);
    let child;

    try {
      child = spawn(launch.command, launch.args, {
        cwd: input.workspacePath,
        shell: false,
        windowsHide: true,
        stdio: ["pipe", "pipe", "pipe"],
      });
    } catch (error: unknown) {
      resolve({
        exitCode: 1,
        stdout: "",
        stderr: error instanceof Error ? error.message : String(error),
      });
      return;
    }

    let stdout = "";
    let stderr = "";
    let settled = false;
    let progressInFlight = false;
    const startedAt = new Date();

    const timeout = setTimeout(() => {
      if (!settled) {
        child.kill();
        stderr += `Codex CLI timed out after ${input.timeoutSeconds} seconds.`;
      }
    }, input.timeoutSeconds * 1000);

    child.stdout.setEncoding("utf8");
    child.stderr.setEncoding("utf8");

    const progressInterval = input.onProgress
      ? setInterval(() => {
          if (settled || progressInFlight || !input.onProgress) {
            return;
          }

          progressInFlight = true;
          input
            .onProgress(buildProgressText(startedAt, stdout, stderr), new Date())
            .catch((error: unknown) => {
              stderr += `\nProgress update failed: ${error instanceof Error ? error.message : String(error)}`;
            })
            .finally(() => {
              progressInFlight = false;
            });
        }, Math.max(1, input.progressIntervalSeconds) * 1000)
      : null;

    child.stdout.on("data", (chunk: string) => {
      stdout += chunk;
    });

    child.stderr.on("data", (chunk: string) => {
      stderr += chunk;
    });

    child.on("error", (error) => {
      settled = true;
      clearTimeout(timeout);
      if (progressInterval) {
        clearInterval(progressInterval);
      }
      resolve({
        exitCode: 1,
        stdout,
        stderr: stderr + error.message,
      });
    });

    child.on("close", (exitCode) => {
      settled = true;
      clearTimeout(timeout);
      if (progressInterval) {
        clearInterval(progressInterval);
      }
      resolve({
        exitCode,
        stdout,
        stderr,
      });
    });

    child.stdin.end(input.prompt, "utf8");
  });
}

function buildProgressText(startedAt: Date, stdout: string, stderr: string): string {
  const elapsedSeconds = Math.max(0, Math.floor((Date.now() - startedAt.getTime()) / 1000));
  const sections = [
    `Codex CLI is still running.`,
    `Elapsed: ${formatElapsed(elapsedSeconds)}`,
    tailSection("Recent stdout", stdout),
    tailSection("Recent stderr", stderr),
  ].filter((value) => value.length > 0);

  return sections.join("\n\n");
}

function tailSection(label: string, value: string): string {
  const trimmed = value.trim();
  if (!trimmed) {
    return "";
  }

  return `${label}:\n${tail(trimmed, 3000)}`;
}

function tail(value: string, maxLength: number): string {
  if (value.length <= maxLength) {
    return value;
  }

  return `...${value.slice(value.length - maxLength + 3)}`;
}

function formatElapsed(totalSeconds: number): string {
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;

  return `${minutes}m ${seconds}s`;
}

function resolveLaunchCommand(commandPath: string, args: string[]): { command: string; args: string[] } {
  if (process.platform === "win32" && /\.(cmd|bat)$/i.test(commandPath)) {
    return {
      command: "cmd.exe",
      args: ["/d", "/s", "/c", commandPath, ...args],
    };
  }

  return {
    command: commandPath,
    args,
  };
}

function cliErrorText(result: RunCodexExecResult, fallback: string): string {
  const stderr = result.stderr.trim();
  const stdout = result.stdout.trim();
  const detail = [stderr, stdout].filter((value) => value.length > 0).join("\n\n");

  if (!detail) {
    return fallback;
  }

  return `${fallback}\n\n${detail}`;
}
